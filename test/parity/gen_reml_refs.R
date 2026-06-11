suppressMessages({library(lme4); library(metafor)})
options(digits=10)

## 1. Random intercept (1|g)
set.seed(101); ng<-12; npg<-6; n<-ng*npg
g<-factor(rep(1:ng,each=npg)); x<-rnorm(n)
b<-rnorm(ng,sd=1.2); y<-2.0+0.8*x+b[as.integer(g)]+rnorm(n,sd=0.9)
d1<-data.frame(y,x,g)
m<-lmer(y~1+x+(1|g),data=d1,REML=TRUE); vc<-as.data.frame(VarCorr(m))
cat("RI sd_g=",vc$sdcor[vc$grp=="g"]," sigma=",vc$sdcor[vc$grp=="Residual"],
    " fixef=",fixef(m)," logLik=",as.numeric(logLik(m)),"\n")
write.csv(d1,"/tmp/ref_ri.csv",row.names=FALSE)

## 2. Crossed intercepts (1|g)+(1|h)
set.seed(202); ng<-8; nh<-6; n<-96
g<-factor(sample(1:ng,n,replace=TRUE)); h<-factor(sample(1:nh,n,replace=TRUE))
x<-rnorm(n); bg<-rnorm(ng,sd=1.0); bh<-rnorm(nh,sd=0.7)
y<-1.0+0.5*x+bg[as.integer(g)]+bh[as.integer(h)]+rnorm(n,sd=0.8)
d2<-data.frame(y,x,g,h)
m2<-lmer(y~1+x+(1|g)+(1|h),data=d2,REML=TRUE); vc2<-as.data.frame(VarCorr(m2))
cat("CROSS sd_g=",vc2$sdcor[vc2$grp=="g"]," sd_h=",vc2$sdcor[vc2$grp=="h"],
    " sigma=",vc2$sdcor[vc2$grp=="Residual"]," fixef=",fixef(m2),
    " logLik=",as.numeric(logLik(m2)),"\n")
write.csv(d2,"/tmp/ref_cross.csv",row.names=FALSE)

## 3. Correlated (1+x|g)
set.seed(303); ng<-15; npg<-8; n<-ng*npg
g<-factor(rep(1:ng,each=npg)); x<-rnorm(n)
library(MASS)
Sig<-matrix(c(1.0,0.3,0.3,0.6),2,2); re<-mvrnorm(ng,c(0,0),Sig)
y<-2.0+0.7*x+re[as.integer(g),1]+re[as.integer(g),2]*x+rnorm(n,sd=0.7)
d3<-data.frame(y,x,g)
m3<-lmer(y~1+x+(1+x|g),data=d3,REML=TRUE); vc3<-as.data.frame(VarCorr(m3))
sd_int<-vc3$sdcor[vc3$grp=="g"&vc3$var1=="(Intercept)"&is.na(vc3$var2)]
sd_slp<-vc3$sdcor[vc3$grp=="g"&vc3$var1=="x"&is.na(vc3$var2)]
sig<-vc3$sdcor[vc3$grp=="Residual"]
cat("CORR sd_int=",sd_int," sd_slope=",sd_slp," sigma=",sig,
    " fixef=",fixef(m3)," logLik=",as.numeric(logLik(m3)),"\n")
write.csv(d3,"/tmp/ref_corr.csv",row.names=FALSE)

## 4. metafor REML meta-analysis (random-effects, intercept only): y_i ~ N(mu, v_i+tau2)
set.seed(404); k<-25; v<-runif(k,0.02,0.3); tau<-0.4
y<-1.3+rnorm(k,sd=sqrt(tau^2))+rnorm(k,sd=sqrt(v))
d4<-data.frame(y,v)
res<-rma(yi=y,vi=v,method="REML")
cat("META mu=",as.numeric(res$beta)," tau2=",res$tau2," se_mu=",res$se,
    " logLik=",as.numeric(logLik(res)),"\n")
write.csv(d4,"/tmp/ref_meta.csv",row.names=FALSE)

## 4b. metafor meta-regression REML: y ~ x, known v
set.seed(414); k<-30; v<-runif(k,0.02,0.25); x<-rnorm(k); tau<-0.3
y<-0.5+0.6*x+rnorm(k,sd=tau)+rnorm(k,sd=sqrt(v))
d4b<-data.frame(y,v,x)
res2<-rma(yi=y,vi=v,mods=~x,method="REML")
cat("METAREG b=",as.numeric(res2$beta)," tau2=",res2$tau2,
    " logLik=",as.numeric(logLik(res2)),"\n")
write.csv(d4b,"/tmp/ref_metareg.csv",row.names=FALSE)
