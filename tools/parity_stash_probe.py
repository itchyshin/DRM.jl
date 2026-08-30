#!/usr/bin/env python3
"""Preserve and replay a bounded stash of modified regular files; never retire it.

Reject additions/deletions, symlinks and nonempty untracked trees in this first
probe. Those need a different recovery slice, not a silently incomplete backup.
Artifacts contain source: keep them private and outside the MIT repository when
probing the GPL R repository.
"""
import argparse
import hashlib
import json
from pathlib import Path
import subprocess
import tempfile


def git(repo, *args):
    return subprocess.run(['git', '-C', str(repo), *args], check=True,
                          stdout=subprocess.PIPE, stderr=subprocess.PIPE).stdout


def blob_id(data):
    return hashlib.sha1(b'blob ' + str(len(data)).encode() + b'\0' + data).hexdigest()


def verify_file(path, record):
    if path.is_symlink() or not path.is_file():
        raise ValueError('restored path is not a regular file: ' + str(path))
    if blob_id(path.read_bytes()) != record['blob']:
        raise ValueError('restored blob mismatch: ' + str(path))
    expected_mode = 0o755 if record['mode'] == '100755' else 0o644
    if path.stat().st_mode & 0o777 != expected_mode:
        raise ValueError('restored mode mismatch: ' + str(path))


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('repo', type=Path)
    parser.add_argument('stash')
    parser.add_argument('output', type=Path)
    args = parser.parse_args()
    stash = git(args.repo, 'rev-parse', '--verify', args.stash + '^{commit}').decode().strip()
    parents = git(args.repo, 'show', '-s', '--format=%P', stash).decode().split()
    if len(parents) not in (2, 3):
        raise ValueError('expected a stash with two or three parents')
    if len(parents) == 3 and git(args.repo, 'ls-tree', '-r', '-z', parents[2]):
        raise ValueError('nonempty untracked tree: outside this bounded probe')
    paths = git(args.repo, 'diff', '--name-only', '-z', parents[0], stash).split(b'\0')[:-1]
    indexed = git(args.repo, 'diff', '--name-only', '-z', parents[0], parents[1]).split(b'\0')[:-1]
    paths = sorted(set(paths + indexed))
    if not paths:
        raise ValueError('empty tracked delta')
    snapshots = {}
    for state, ref in [('base', parents[0]), ('index', parents[1]), ('worktree', stash)]:
        entries = {}
        for rawpath in paths:
            path = rawpath.decode('utf-8')
            if Path(path).is_absolute() or '..' in Path(path).parts:
                raise ValueError('unsafe relative path')
            record = git(args.repo, 'ls-tree', '-z', ref, '--', path).rstrip(b'\0')
            header, found = record.split(b'\t', 1)
            mode, kind, oid = header.decode().split()
            if mode not in ('100644', '100755') or kind != 'blob' or found != rawpath:
                raise ValueError('only modified regular files are supported')
            data = git(args.repo, 'cat-file', 'blob', oid)
            if blob_id(data) != oid:
                raise ValueError('Git blob verification failed')
            entries[path] = {'mode': mode, 'blob': oid, 'sha256': hashlib.sha256(data).hexdigest(), 'bytes': data}
        snapshots[state] = entries
    args.output.mkdir(parents=True, exist_ok=False)
    for state, entries in snapshots.items():
        for path, record in entries.items():
            target = args.output / state / path
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_bytes(record['bytes'])
            target.chmod(0o755 if record['mode'] == '100755' else 0o644)
    patches = {}
    for name, before, after in [('index.patch', parents[0], parents[1]), ('worktree.patch', parents[1], stash)]:
        patches[name] = git(args.repo, 'diff', '--binary', '--full-index', before, after)
        (args.output / name).write_bytes(patches[name])
    # Replay saved patches against saved bases, without referring to source Git.
    with tempfile.TemporaryDirectory(prefix='stash-replay-') as scratch:
        dest = Path(scratch)
        for path, record in snapshots['base'].items():
            p = dest / path
            p.parent.mkdir(parents=True, exist_ok=True)
            p.write_bytes((args.output / 'base' / path).read_bytes())
            p.chmod(0o755 if record['mode'] == '100755' else 0o644)
        for state, patch in [('index', 'index.patch'), ('worktree', 'worktree.patch')]:
            if patches[patch]:
                git(dest, 'apply', str((args.output / patch).resolve()))
            for path, record in snapshots[state].items():
                restored_path = dest / path
                verify_file(restored_path, record)
                # A deliberately damaged restored file must fail the same oracle.
                restored = restored_path.read_bytes()
                restored_path.write_bytes(restored + b'\nDAMAGE\n')
                try:
                    verify_file(restored_path, record)
                except ValueError:
                    pass
                else:
                    raise ValueError('damaged-restore negative control was accepted')
                finally:
                    restored_path.write_bytes(restored)
                verify_file(restored_path, record)
    receipt = {'status': 'RECOVERY_PROBE_PASS', 'repo': str(args.repo.resolve()),
               'stash': stash, 'parents': parents, 'untracked_tree_empty': len(parents) == 3,
               'scope': 'modified regular files only; private saved-base replay; no retirement',
               'restored_files_per_state': len(paths), 'damaged_restore_rejected': True,
               'snapshots': {state: {path: {k: v for k, v in record.items() if k != 'bytes'}
                                    for path, record in entries.items()} for state, entries in snapshots.items()},
               'patch_sha256': {k: hashlib.sha256(v).hexdigest() for k, v in patches.items()}}
    (args.output / 'receipt.json').write_text(json.dumps(receipt, indent=2) + '\n')
    print('RECOVERY_PROBE_PASS', stash, 'files=' + str(len(paths)), 'retired=0')


if __name__ == '__main__':
    main()
