#!/usr/bin/env python3
"""Independent dense joint-normal oracle for generated native two-predictor data.

Production integrates the missing subset directly. This oracle instead forms
Cov(y,x1,x2), factors its observed submatrix, and conditions a multivariate
normal. It does not use fitted Julia covariance or implementation helpers.
"""
import hashlib
import json
import math
import sys
from pathlib import Path

ORDER = ['beta0','beta_z','b1','b2','logsigma','alpha10','alpha1z','logtau1','alpha20','alpha2z','logtau2']


def require(ok, message):
    if not ok:
        raise ValueError(message)


def vector(x, n, label):
    require(isinstance(x, list) and len(x) == n, label + ': dimension')
    require(all(type(v) in (int,float) and math.isfinite(v) for v in x), label + ': finite')


def cholesky(a):
    n = len(a)
    L = [[0.0]*n for _ in range(n)]
    for i in range(n):
        for j in range(i+1):
            r = a[i][j]-sum(L[i][k]*L[j][k] for k in range(j))
            if i == j:
                require(r > 0 and math.isfinite(r), 'covariance positive definite')
                L[i][j] = math.sqrt(r)
            else:
                L[i][j] = r/L[j][j]
    return L


def solve(L,b):
    n = len(b); u = [0.0]*n; x = [0.0]*n
    for i in range(n):
        u[i]=(b[i]-sum(L[i][j]*u[j] for j in range(i)))/L[i][i]
    for i in reversed(range(n)):
        x[i]=(u[i]-sum(L[j][i]*x[j] for j in range(i+1,n)))/L[i][i]
    return x


def row(theta, f, i):
    b0,bz,b1,b2,ls,a10,a1z,lt1,a20,a2z,lt2=theta
    S,T1,T2=math.exp(2*ls),math.exp(2*lt1),math.exp(2*lt2)
    m1,m2=a10+a1z*f['z'][i],a20+a2z*f['z'][i]
    mean=[b0+bz*f['z'][i]+b1*m1+b2*m2,m1,m2]
    cov=[[S+b1*b1*T1+b2*b2*T2,b1*T1,b2*T2],[b1*T1,T1,0.0],[b2*T2,0.0,T2]]
    values=[f['y'][i],f['x1'][i],f['x2'][i]]
    obs=[j for j,k in enumerate(('y','x1','x2')) if f[k+'_observed'][i]]
    missing=[j for j in (1,2) if j not in obs]
    posterior=[values[j] if j in obs else mean[j] for j in (1,2)]
    conditional=[[0.0,0.0],[0.0,0.0]]
    if not obs:
        return 0.0,posterior,[[T1,0.0],[0.0,T2]]
    L=cholesky([[cov[j][k] for k in obs] for j in obs])
    residual=[values[j]-mean[j] for j in obs]
    score=solve(L,residual)
    ll=-0.5*(len(obs)*math.log(2*math.pi)+2*sum(math.log(L[j][j]) for j in range(len(obs)))+sum(a*b for a,b in zip(residual,score)))
    for j in missing:
        posterior[j-1]=mean[j]+sum(cov[j][k]*score[l] for l,k in enumerate(obs))
        for k in missing:
            v=solve(L,[cov[l][k] for l in obs])
            conditional[j-1][k-1]=cov[j][k]-sum(cov[j][l]*v[h] for h,l in enumerate(obs))
    require(math.isfinite(ll), "computed likelihood nonfinite")
    vector(posterior,2,"computed posterior mean")
    return ll,posterior,conditional


def nll(theta,f):
    value=-sum(row(theta,f,i)[0] for i in range(len(f['y'])))
    require(math.isfinite(value),'computed likelihood nonfinite')
    return value


def check_conditional_covariance(C,theta,f,i):
    require(isinstance(C,list) and len(C)==2,'conditional covariance shape')
    for line in C:
        vector(line,2,'conditional covariance')
    require(abs(C[0][1]-C[1][0])<=1e-10,'conditional covariance symmetry')
    missing=[j for j,k in enumerate(('x1','x2')) if not f[k+'_observed'][i]]
    for j in range(2):
        if j not in missing:
            require(all(abs(C[j][k])<=1e-10 and abs(C[k][j])<=1e-10 for k in range(2)),'observed conditional covariance')
    if not missing:
        return
    # Independent conditional PRECISION, distinct from row()'s covariance Schur.
    precision=[[0.0]*len(missing) for _ in missing]
    for a,j in enumerate(missing):
        for b,k in enumerate(missing):
            precision[a][b]=(math.exp(-2*theta[7 if j==0 else 10]) if j==k else 0.0)
            if f['y_observed'][i]:
                precision[a][b]+=theta[2+j]*theta[2+k]*math.exp(-2*theta[4])
    delta=max(abs(sum(C[j][k]*precision[c][b] for c,k in enumerate(missing))-(1.0 if a==b else 0.0))
              for a,j in enumerate(missing) for b in range(len(missing)))
    require(delta<=1e-9,'conditional precision identity')
    cholesky([[C[j][k] for k in missing] for j in missing])


def jacobian(theta,f,i):
    J=[[0.0]*11 for _ in range(2)]
    for k in range(11):
        hi,lo=list(theta),list(theta); h=1e-5*max(1,abs(theta[k]))
        hi[k]+=h;lo[k]-=h
        a,b=row(hi,f,i)[1],row(lo,f,i)[1]
        for j in range(2):
            J[j][k]=(a[j]-b[j])/(2*h)
    return J


def check(r):
    require(r.get('schema')=='two_gaussian_reference_v1','schema')
    require(r.get('source_unchanged') is True and r.get('source_before')==r.get('source_after'),'source changed')
    anchor_path=Path(__file__).resolve().parents[1]/'test/fixtures/joint_missing_predictor/two_gaussian_provenance.json'
    anchor=json.loads(anchor_path.read_text())
    require(bool(anchor['source_before']) and r.get('source_before')==anchor['source_before'],'frozen source provenance')
    for key in ('runner_sha256','loaded_native_DLL_sha256','R_version','TMB_version'):
        require(r.get(key)==anchor[key],'frozen '+key)
    require(r.get('optimizer_control')==[],'default optimizer controls')
    require(type(r.get('native_convergence')) is int and r['native_convergence']==0,'native convergence')
    require(r.get('raw_order')==ORDER,'parameter order')
    f=r.get('fixture',{});n=160
    require(set(f)=={'y','x1','x2','z','y_observed','x1_observed','x2_observed','original_row'},'fixture fields')
    for k in ('y','x1','x2','z'):
        vector(f[k],n,k)
    require(f['original_row']==list(range(1,n+1)), 'row identity')
    for k in ('y','x1','x2'):
        require(isinstance(f[k+'_observed'],list) and len(f[k+'_observed'])==n and all(type(v) is bool for v in f[k+'_observed']),k+': mask')
    masks={''.join(str(int(f[k+'_observed'][i])) for k in ('y','x1','x2')) for i in range(n)}
    require(masks=={'000','001','010','011','100','101','110','111'},'eight masks')
    counts={key:sum(''.join(str(int(f[k+'_observed'][i])) for k in ('y','x1','x2'))==key for i in range(n)) for key in masks}
    require(r.get('mask_counts')==counts,'mask counts')
    require(r.get('nobs')==sum(f['y_observed'])==156,'response nobs')
    theta=r.get('theta');vector(theta,11,'theta')
    V=r.get('covariance');require(isinstance(V,list) and len(V)==11,'V dimension')
    for line in V:
        vector(line,11,'V row')
    require(max(abs(V[i][j]-V[j][i]) for i in range(11) for j in range(11))<1e-10,'V symmetry')
    cholesky(V)
    points=r.get('points');require(isinstance(points,list) and len(points)==3,'point denominator')
    require(points[0]['theta']==theta,'native fitted point')
    shift=[.05,-.04,.03,-.06,.025,-.035,.045,.055,-.025,.015,-.045]
    errors={'nll':0.0,'gradient':0.0,'mean':0.0,'se':0.0,'prediction':0.0}
    for point,multiple in zip(points,(0,1,-2)):
        t=point.get('theta');vector(t,11,'point theta');vector(point.get('gradient'),11,'point gradient')
        require(max(abs(t[k]-(theta[k]+multiple*shift[k])) for k in range(11))<1e-12,'point perturbation')
        require(type(point.get('nll')) in (int,float) and math.isfinite(point['nll']), 'point objective')
        errors['nll']=max(errors['nll'],abs(nll(t,f)-point['nll']))
        for i in range(n):
            check_conditional_covariance(row(t,f,i)[2],t,f,i)
        for k in range(11):
            hi,lo=list(t),list(t);h=1e-5*max(1,abs(t[k]));hi[k]+=h;lo[k]-=h
            score=(nll(hi,f)-nll(lo,f))/(2*h)
            require(math.isfinite(score),'computed gradient nonfinite')
            errors['gradient']=max(errors['gradient'],abs(score-point['gradient'][k]))
    require(type(r.get('loglik')) in (int,float) and math.isfinite(r['loglik']) and abs(r['loglik']+points[0]['nll'])<1e-8,'native loglik')
    vector(r.get('prediction'),n,'prediction')
    for j in range(2):
        records=r.get('imputed'+str(j+1));require(isinstance(records,list) and len(records)==n,'imputation denominator')
        for i,record in enumerate(records):
            key='x'+str(j+1);observed=f[key+'_observed'][i]
            require(record.get('original_row')==i+1 and record.get('model_row')==i+1 and record.get('variable')==key and record.get('observed') is observed,'imputation identity')
            require(record.get('uncertainty_status')=='ok','uncertainty status')
            require(record.get('source')==('observed' if observed else 'conditional_mode'),'imputation source')
            _,means,C=row(theta,f,i)
            require(type(record.get('estimate')) in (int,float) and math.isfinite(record['estimate']),'imputation estimate')
            errors['mean']=max(errors['mean'],abs(means[j]-record['estimate']))
            if observed:
                require(record.get('std_error')=='NA','observed SE unavailable')
            else:
                J=jacobian(theta,f,i)[j]
                se=math.sqrt(C[j][j]+sum(J[k]*V[k][l]*J[l] for k in range(11) for l in range(11)))
                require(type(record.get('std_error')) in (int,float) and math.isfinite(record['std_error']),'missing SE')
                require(math.isfinite(se),'computed SE nonfinite')
                errors['se']=max(errors['se'],abs(se-record['std_error']))
            expected=theta[0]+theta[1]*f['z'][i]+theta[2]*means[0]+theta[3]*means[1]
            require(math.isfinite(expected),'computed prediction nonfinite')
            errors['prediction']=max(errors['prediction'],abs(expected-r['prediction'][i]))
    for key,tol in {'nll':1e-7,'gradient':1e-5,'mean':1e-7,'se':1e-6,'prediction':1e-7}.items():
        require(math.isfinite(errors[key]) and errors[key]<=tol,key+': numerical mismatch '+str(errors[key]))
    return errors


def export(r,src,out):
    require(not out.exists(),'refusing stale fixture')
    fields={'native_reference_sha256':hashlib.sha256(src.read_bytes()).hexdigest(),
            'raw_order':r['raw_order'],**r['fixture'],'theta':r['theta'],'covariance':r['covariance']}
    for j in range(1,3):
        rows=r['imputed'+str(j)]
        fields['imputed'+str(j)+'_mean']=[q['estimate'] for q in rows]
        fields['imputed'+str(j)+'_se']=[0.0 if q['std_error']=='NA' else q['std_error'] for q in rows]
        fields['imputed'+str(j)+'_se_available']=[q['std_error']!='NA' for q in rows]
    lines=[k+' = '+json.dumps(v,allow_nan=False) for k,v in fields.items()]
    for p in r['points']:
        lines.append('\n[[points]]')
        lines.extend(k+' = '+json.dumps(v,allow_nan=False) for k,v in p.items())
    out.write_text('\n'.join(lines)+'\n')


if __name__=='__main__':
    if len(sys.argv) not in (2,3):
        raise SystemExit('usage: check_two_gaussian_reference.py NATIVE_JSON [NEW_TOML]')
    src=Path(sys.argv[1]);r=json.loads(src.read_text());errors=check(r)
    if len(sys.argv)==3:
        export(r,src,Path(sys.argv[2]))
    print('TWO_GAUSSIAN_REFERENCE_PASS rows=160 masks=8 points=3 '+json.dumps(errors,sort_keys=True))
