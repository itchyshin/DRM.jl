import { defineConfig } from 'vitepress'
import { tabsMarkdownPlugin } from 'vitepress-plugin-tabs'
import { mathjaxPlugin } from './mathjax-plugin'
import { juliaReplTransformer } from './julia-repl-transformer'
import footnote from "markdown-it-footnote";
import path from 'path'

const mathjax = mathjaxPlugin()

function getBaseRepository(base: string): string {
  if (!base || base === '/') return '/';
  const parts = base.split('/').filter(Boolean);
  return parts.length > 0 ? `/${parts[0]}/` : '/';
}

const baseTemp = {
  base: '/DRM.jl/v0.1/',// TODO: replace this in makedocs!
}

const navTemp = {
  nav: [
{ text: 'Home', link: '/index' },
{ text: 'Get started', link: '/get-started' },
{ text: 'Model Guides', collapsed: false, items: [
{ text: 'What can I fit today?', link: '/model-guides/model-map' },
{ text: 'Which scale are you modelling?', link: '/model-guides/which-scale' },
{ text: 'Choosing response families', link: '/model-guides/distribution-families' },
{ text: 'Checking and using fitted models', link: '/model-guides/model-workflow' },
{ text: 'Improving convergence', link: '/model-guides/convergence' },
{ text: 'Working with large data', link: '/model-guides/large-data' }]
 },
{ text: 'Tutorials', collapsed: false, items: [
{ text: 'When variance carries signal', link: '/tutorials/location-scale' },
{ text: 'Robust continuous responses', link: '/tutorials/robust-student' },
{ text: 'Count abundance and extra zeros', link: '/tutorials/count-nbinom2' },
{ text: 'Proportions and success rates', link: '/tutorials/proportion-beta-binomial' },
{ text: 'Changing residual coupling with rho12', link: '/tutorials/bivariate-coscale' },
{ text: 'Mean effects and residual heterogeneity', link: '/tutorials/meta-analysis' },
{ text: 'Structural dependence overview', link: '/tutorials/structural-dependence' },
{ text: 'Animal models and additive relatedness', link: '/tutorials/animal-models' },
{ text: 'Phylogenetic structured effects', link: '/tutorials/phylogenetic-models' },
{ text: 'Coordinate-spatial structured effects', link: '/tutorials/spatial-models' },
{ text: 'Known-matrix relatedness with relmat', link: '/tutorials/relmat-known-matrices' },
{ text: 'Structural dependence details', link: '/tutorials/phylogenetic-spatial' }]
 },
{ text: 'Diagnostics & Validation', collapsed: false, items: [
{ text: 'Figure gallery', link: '/diagnostics-and-validation/figure-gallery' },
{ text: 'Implementation map', link: '/diagnostics-and-validation/implementation-map' },
{ text: 'Testing likelihoods', link: '/diagnostics-and-validation/testing-likelihoods' },
{ text: 'Simulation plot grammar', link: '/diagnostics-and-validation/simulation-plot-grammar' }]
 },
{ text: 'Developer Notes', collapsed: false, items: [
{ text: 'Formula grammar', link: '/developer-notes/formula-grammar' },
{ text: 'Adding distribution families', link: '/developer-notes/adding-families' },
{ text: 'Implemented source map', link: '/developer-notes/source-map' }]
 },
{ text: 'Reference', collapsed: false, items: [
{ text: 'Package', link: '/reference/package' },
{ text: 'Model specification', link: '/reference/model-specification' },
{ text: 'Structured-effect markers', link: '/reference/structured-effect-markers' },
{ text: 'Deprecated marker internals', link: '/reference/deprecated-marker-internals' },
{ text: 'Model fitting and post-fit tools', link: '/reference/model-fitting-and-postfit' },
{ text: 'Visualization', link: '/reference/visualization' }]
 },
{ text: 'R ↔ Julia bridge', link: '/r-julia-bridge' },
{ text: 'Rosetta (R ↔ Julia)', link: '/rosetta' },
{ text: 'Changelog', link: '/changelog' }
]
,
}

const nav = [
  ...navTemp.nav,
  {
    component: 'VersionPicker'
  }
]

// https://vitepress.dev/reference/site-config
export default defineConfig({
  base: '/DRM.jl/v0.1/',// TODO: replace this in makedocs!
  title: 'DRM.jl',
  description: 'Documentation for DRM.jl',
  lastUpdated: true,
  cleanUrls: true,
  outDir: '../2', // This is required for MarkdownVitepress to work correctly...
  head: [
    
    ['script', {src: `${getBaseRepository(baseTemp.base)}versions.js`}],
    // ['script', {src: '/versions.js'], for custom domains, I guess if deploy_url is available.
    ['script', {src: `${baseTemp.base}siteinfo.js`}]
  ],
  
  markdown: {
    codeTransformers: [juliaReplTransformer()],
    config(md) {
      md.use(tabsMarkdownPlugin);
      md.use(footnote);
      mathjax.markdownConfig(md);
    },
    theme: {
      light: "github-light",
      dark: "github-dark"
    },
  },
  vite: {
    plugins: [
      mathjax.vitePlugin,
    ],
    define: {
      __DEPLOY_ABSPATH__: JSON.stringify('/DRM.jl'),
    },
    resolve: {
      alias: {
        '@': path.resolve(__dirname, '../components')
      }
    },
    optimizeDeps: {
      exclude: [ 
        '@nolebase/vitepress-plugin-enhanced-readabilities/client',
        'vitepress',
        '@nolebase/ui',
      ], 
    }, 
    ssr: { 
      noExternal: [ 
        // If there are other packages that need to be processed by Vite, you can add them here.
        '@nolebase/vitepress-plugin-enhanced-readabilities',
        '@nolebase/ui',
      ], 
    },
  },
  themeConfig: {
    outline: 'deep',
    
    search: {
      provider: 'local',
      options: {
        detailedView: true
      }
    },
    nav,
    sidebar: [
{ text: 'Home', link: '/index' },
{ text: 'Get started', link: '/get-started' },
{ text: 'Model Guides', collapsed: false, items: [
{ text: 'What can I fit today?', link: '/model-guides/model-map' },
{ text: 'Which scale are you modelling?', link: '/model-guides/which-scale' },
{ text: 'Choosing response families', link: '/model-guides/distribution-families' },
{ text: 'Checking and using fitted models', link: '/model-guides/model-workflow' },
{ text: 'Improving convergence', link: '/model-guides/convergence' },
{ text: 'Working with large data', link: '/model-guides/large-data' }]
 },
{ text: 'Tutorials', collapsed: false, items: [
{ text: 'When variance carries signal', link: '/tutorials/location-scale' },
{ text: 'Robust continuous responses', link: '/tutorials/robust-student' },
{ text: 'Count abundance and extra zeros', link: '/tutorials/count-nbinom2' },
{ text: 'Proportions and success rates', link: '/tutorials/proportion-beta-binomial' },
{ text: 'Changing residual coupling with rho12', link: '/tutorials/bivariate-coscale' },
{ text: 'Mean effects and residual heterogeneity', link: '/tutorials/meta-analysis' },
{ text: 'Structural dependence overview', link: '/tutorials/structural-dependence' },
{ text: 'Animal models and additive relatedness', link: '/tutorials/animal-models' },
{ text: 'Phylogenetic structured effects', link: '/tutorials/phylogenetic-models' },
{ text: 'Coordinate-spatial structured effects', link: '/tutorials/spatial-models' },
{ text: 'Known-matrix relatedness with relmat', link: '/tutorials/relmat-known-matrices' },
{ text: 'Structural dependence details', link: '/tutorials/phylogenetic-spatial' }]
 },
{ text: 'Diagnostics & Validation', collapsed: false, items: [
{ text: 'Figure gallery', link: '/diagnostics-and-validation/figure-gallery' },
{ text: 'Implementation map', link: '/diagnostics-and-validation/implementation-map' },
{ text: 'Testing likelihoods', link: '/diagnostics-and-validation/testing-likelihoods' },
{ text: 'Simulation plot grammar', link: '/diagnostics-and-validation/simulation-plot-grammar' }]
 },
{ text: 'Developer Notes', collapsed: false, items: [
{ text: 'Formula grammar', link: '/developer-notes/formula-grammar' },
{ text: 'Adding distribution families', link: '/developer-notes/adding-families' },
{ text: 'Implemented source map', link: '/developer-notes/source-map' }]
 },
{ text: 'Reference', collapsed: false, items: [
{ text: 'Package', link: '/reference/package' },
{ text: 'Model specification', link: '/reference/model-specification' },
{ text: 'Structured-effect markers', link: '/reference/structured-effect-markers' },
{ text: 'Deprecated marker internals', link: '/reference/deprecated-marker-internals' },
{ text: 'Model fitting and post-fit tools', link: '/reference/model-fitting-and-postfit' },
{ text: 'Visualization', link: '/reference/visualization' }]
 },
{ text: 'R ↔ Julia bridge', link: '/r-julia-bridge' },
{ text: 'Rosetta (R ↔ Julia)', link: '/rosetta' },
{ text: 'Changelog', link: '/changelog' }
]
,
    sidebarDrawer: false,
    editLink: { pattern: "https://https://github.com/itchyshin/DRM.jl/edit/main/docs/src/:path" },
    socialLinks: [
      { icon: 'github', link: 'https://github.com/itchyshin/DRM.jl' }
    ],
    footer: {
      message: 'Made with <a href="https://luxdl.github.io/DocumenterVitepress.jl/dev/" target="_blank"><strong>DocumenterVitepress.jl</strong></a><br>',
      copyright: `© Copyright ${new Date().getUTCFullYear()}.`
    }
  }
})
