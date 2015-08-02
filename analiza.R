# install the RODBC package
#install.packages("RODBC")

#### database fetch ####

# load the package
library(RODBC)

# connect to you new data source
db <- odbcConnect("infobright-wybory2015prez1", uid="root", pwd="",DBMSencoding="UTF8",readOnlyOptimize=TRUE,interpretDot=TRUE)

# whoe the names of the available tables
sqlTables(db)

qry <- "
SELECT
        w.id,w.lp,w.kandydat,w.glosy,
        pu.val as uprawnieni,pk.val as kartywydane,pn.val as glosyniewazne,
        o.woj,o.powiat,o.gmina,t.typgminy
FROM
        (SELECT id,lp,kandydat,SUM(t.glosy) AS glosy FROM wybory2015prez2.wyniki AS t GROUP BY id,lp,kandydat) AS w,
        wybory2015prez2.obwody AS o,
        wybory2015prez2.protokoly AS pu,
        wybory2015prez2.protokoly AS pk,
        wybory2015prez2.protokoly AS pn,
        wybory2015prez2.gminyteryt AS t
WHERE
        w.id=o.id AND
        o.teryt=t.teryt AND
        w.id=pu.id AND 
        w.id=pk.id AND 
        w.id=pn.id AND 
        pu.item=1 AND 
        pk.item=4 AND
        pn.item=12
"

# load a_table into a data fram
dfgminy <- sqlQuery(db, qry, stringsAsFactors=TRUE)

dfgminy$shortlista<-factor(dfgminy$kandydat,levels = c(
        "Duda Andrzej Sebastian",
        "Komorowski Bronisław Maria"
        ),labels = c(
        "Duda",
        "Komorowski")
)
table(dfgminy$kandydat,dfgminy$shortlista)

dfgminy$frekwencja <- dfgminy$kartywydane / dfgminy$uprawnieni
dfgminy$rezultat.lista <- dfgminy$glosy / dfgminy$kartywydane
dfgminy$rezultat.niewazne <- dfgminy$glosyniewazne / dfgminy$kartywydane
dfgminy$ve <- dfgminy$glosy/dfgminy$uprawnieni
dfgminy$frek2 <- (dfgminy$kartywydane-dfgminy$glosyniewazne)/dfgminy$uprawnieni

dfgminy$typgminy[dfgminy$typgminy %in% c("Gmina miejska","Dzielnica")]<-"Miasto"
dfgminy$typgminy<-droplevels(dfgminy$typgminy)
levels(dfgminy$typgminy)<-c("Wieś","Miasto")

listy<-c("Komorowski","Duda")
kolory<-c("#ff7f0040","#377eb840")
koloryf<-c("#ff7f00","#377eb8")

save(list=c("dfgminy","listy","kolory","koloryf"),file="data.Rda")

# close the connection
odbcClose(db)

#####################################

# jak w raporcie http://samarcandanalytics.com/?page_id=39 ####

rm(list=ls())
load("data.Rda")

dfgminy <- dfgminy[dfgminy$uprawnieni>=100,]

library(lattice)

stopka<-function() {
        trellis.focus("toplevel")
        panel.text(0.85,0.02,"http://niepewnesondaze.blogspot.com",col="gray")
        trellis.unfocus()
}

png(filename=paste0("freqlista2-razem.png"),width=809,height=655,type="windows",antialias="cleartype")
plot(dfgminy$frekwencja[dfgminy$shortlista==listy[1]],dfgminy$rezultat.lista[dfgminy$shortlista==listy[1]],pch = ".",type="n",
     xlab="Frekwencja",ylab="Poparcie dla kandydata",xlim=c(0,1),ylim=c(0,1),
     main="Wybory prezydenckie 2015 (II tura)",
     sub="(każdy punkt to jeden obwód wyborczy)")

for (i in 1:length(listy)) {
        points(dfgminy$frekwencja[dfgminy$shortlista==listy[i]],
               dfgminy$rezultat.lista[dfgminy$shortlista==listy[i]],
               col=kolory[i],
               pch = ".")
}
legend(x=0,y=1,legend=listy,fill=koloryf,bty="n")
dev.off()

for (i in 1:length(listy)) {
        png(filename=paste0("freqlista2-",listy[i],".png"),width=809,height=655,type="windows",antialias="cleartype")        
        plot(dfgminy$frekwencja[dfgminy$shortlista==listy[i]],dfgminy$rezultat.lista[dfgminy$shortlista==listy[i]],col=kolory[i],pch = ".",
                xlab="Frekwencja",ylab=paste0("Poparcie dla kandydata"),xlim=c(0,1),ylim=c(0,1),
                main=paste0("Wybory prezydenckie 2015 (II tura) - ",listy[i]),
                sub="(każdy punkt to jeden obwód wyborczy)")
        dev.off()
}


png(filename=paste0("freqlista2-listy.png"),width=809,height=655,type="windows",antialias="cleartype")
xyplot(rezultat.lista~frekwencja|shortlista,data=dfgminy[dfgminy$shortlista %in% listy,],col="#ffaa1140",pch=".",
       xlab="Frekwencja",ylab="Poparcie dla kandydata",xlim=c(0,1),ylim=c(0,1),
       main="Wyniki w obwodach")
stopka()
dev.off()

### głosowanie w regionach ####

for (i in 1:length(listy)) {
png(filename=paste0("freqlistawoj2-",listy[i],".png"),width=809,height=655,type="windows",antialias="cleartype")        
print(xyplot(rezultat.lista~frekwencja|woj,data=dfgminy[dfgminy$shortlista==listy[i],],pch=".",col=kolory[i],
       xlab="Frekwencja",ylab="Poparcie dla kandydata",xlim=c(0,1),ylim=c(0,1),
       main=paste0("Wynik kandydata ",listy[i]," w województwach (II tura)"),
       sub="każdy punkt to jeden obwód wyborczy"
        ))
stopka()
dev.off()
}

### frekwencja ####

png(filename=paste0("frekwencja2.png"),width=809,height=655,type="windows",antialias="cleartype")        
hist(dfgminy$frekwencja[dfgminy$lp==1],breaks = 50,ylab="Liczba obwodów",xlab="Frekwencja",main="Frekwencja w obwodach (II tura)",col="gold")
dev.off()

png(filename=paste0("frekwencja2-woj.png"),width=809,height=655,type="windows",antialias="cleartype")        
histogram(~frekwencja|woj,data=dfgminy[dfgminy$lp==1,],type="count",breaks=25,xlab="Frekwencja",ylab="Liczba obwodów",main="Frekwencja w województwach (II tura)",col="gold")
stopka()
dev.off()

### poparcie dla partii / histogram ####

png(filename=paste0("histogram2-lista.png"),width=809,height=655,type="windows",antialias="cleartype")        
histogram(~rezultat.lista|shortlista,data=dfgminy[dfgminy$shortlista %in% listy,],
          type="count",breaks=25,
          xlab="Wynik kandydata",
          ylab="Liczba obwodów",
          layout=c(length(listy),1),
          main="Wynik a liczba obwodów",
          col="gold")
dev.off()

# typ obwodu: wyniki list ####

png(filename=paste0("typ-listy2.png"),width=809,height=655,type="windows",antialias="cleartype")
xyplot(rezultat.lista~frekwencja|typgminy+shortlista,data=dfgminy[dfgminy$shortlista %in% listy,],col=kolory[1],pch=".",
       xlab="Frekwencja",ylab="Poparcie dla kandydata",xlim=c(0,1),ylim=c(0,1),auto.key=TRUE,
       main="Wyniki list w obwodach (II tura)")
stopka()
dev.off()

# typ obwodu: frekwencja ####

f1<-hist(dfgminy$frekwencja[dfgminy$lp==1 & dfgminy$typgminy=="Miasto"],breaks = 100,plot=FALSE)
f2<-hist(dfgminy$frekwencja[dfgminy$lp==1 & dfgminy$typgminy=="Wieś"],breaks = 100,plot=FALSE)

png(filename=paste0("typ2-frek-1.png"),width=809,height=655,type="windows",antialias="cleartype")
plot(f1$breaks[-1],f1$counts,type="s",col="blue",lwd=2,main="Frekwencja wg typu obwodów (II tura)",ylab="Liczba obwodów",xlab="Frekwencja")
lines(f2$breaks[-1],f2$counts,type="s",col="red",lwd=2)
legend(x=0,y=800,fill=c("blue","red"),legend = c("Miasto","Wieś"),bty="n",cex=0.8)
dev.off()

# tu ładnie widać
png(filename=paste0("typ2-frek-2.png"),width=809,height=655,type="windows",antialias="cleartype")
histogram(~frekwencja|typgminy,data=dfgminy[dfgminy$lp==1,],
          type="percent",breaks=50,
          xlab="Frekwencja",
          ylab="Odsetek obwodów",
          main="Frekwencja a typ obwodu (II tura)",
          layout=c(1,2),
          col="gold")
stopka()
dev.off()

png(filename=paste0("typ2-listy-2.png"),width=809,height=655,type="windows",antialias="cleartype")
histogram(~rezultat.lista|shortlista+typgminy,data=dfgminy[dfgminy$shortlista %in% listy,],
          type="percent",breaks=25,
          xlab="Wynik kandydata",
          ylab="Odsetek obwodów",
          main="Wyniki a typ obwodu (II tura)",
          col="gold")
stopka()
dev.off()

## ciekawostki ####

rm(list=ls())
load("data.Rda")

dfgminy<-dfgminy[(dfgminy$kartywydane-dfgminy$glosyniewazne)>100,]

# gdzie jest najwieksze poparcie? (co najmniej 100 kart waznych) ####

listymax=list()
for (i in listy) {
        df <- dfgminy[dfgminy$shortlista==i,]
        dfid<-df$id[df$rezultat.lista==max(df$rezultat.lista,na.rm=TRUE)]
        listymax$id[i] <- dfid[!is.na(dfid)][1]
}

# load the package
library(RODBC)
# connect to you new data source
db <- odbcConnect("infobright-wybory2015prez1", uid="root", pwd="",DBMSencoding="UTF8",readOnlyOptimize=TRUE,interpretDot=TRUE)
qry <- paste0("SELECT * FROM wybory2015prez2.obwody WHERE obwody.id IN (",paste(unlist(listymax),collapse = ","),")")
dfmax <- sqlQuery(db, qry, stringsAsFactors=TRUE)
odbcClose(db)

obwodymax<-data.frame()
for (l in listy) {
        obwodymax<-rbind(obwodymax,cbind(
                dfmax[dfmax$id==listymax$id[l],c("woj","powiat","gmina","siedziba","id")],
                dfgminy[dfgminy$id==listymax$id[l] & dfgminy$shortlista==l,c("shortlista","uprawnieni","kartywydane","glosyniewazne","glosy","rezultat.lista")]
        ))
}
write.table(obwodymax,"obwodymax.csv",col.names = TRUE,row.names = FALSE,sep=";",dec=",",fileEncoding="UTF8")

# inne próby, dotąd przygotowane dla wyborów prezydenckich, niżej dla samorządowych ####

#### processing ####

rm(list=ls())
load("data.Rda")

# at least 100 voters to remove extremes
dfgminy <- dfgminy[dfgminy$uprawnieni>=100,]
# focus on big players
dfgminy <- dfgminy[dfgminy$shortlista %in% listy,]

# precyzja
xlx<-seq(0,1,.005)
my.palette<-hsv(h=seq(from=4/6,to=0,length=4096),s=1,v=1) 

x <- dfgminy[dfgminy$lp==1,]

par(mfrow=c(1,2))
kor.f.rezultat<-cor(x$frekwencja,x$rezultat.lista,use = "complete.obs")
x$f.freq <- cut(x$frekwencja,breaks=xlx,right=FALSE)
x$f.rezultat.lista <- cut(x$rezultat.lista,breaks=xlx,right=FALSE)
t.nstations <- table(x$f.freq,x$f.rezultat.lista)
image(t.nstations,xlab="Frekwencja",ylab="Wynik listy",main="Liczba komisji",sub=paste0("Korelacja wyniku z frekwencją ",round(kor.f.rezultat,2)*100,"%"),col=my.palette)
#xl<-loess(x$rezultat.lista~x$frekwencja)
#lines(xlx,predict(xl,newdata = xlx),col="black",lwd=2)
t.nglosy <- xtabs(x$glosy~x$f.freq+x$f.rezultat.lista)
image(t.nglosy,xlab="Frekwencja",ylab="Wynik listy",main="Liczba głosów",col=my.palette)
par(mfrow=c(1,1))

### try with other functions ####

filled.contour(t.nstations,xlim=c(0,1),ylim=c(0,1),
               nlevels=20,
               axes=TRUE,
               col=hsv(h=seq(from=4/6,to=0,length=21),s=1,v=1),
               xlab="Frekwencja",ylab="Wynik listy",main=unique(x$shortlista)
               #color.palette=topo.colors
)

Lab.palette <- colorRampPalette(c("blue", "orange", "red"), space = "Lab")
smoothScatter(x$frekwencja,x$rezultat.lista,xlim = c(0,1),ylim=c(0,1),colramp = Lab.palette,nrpoints=0)
smoothScatter(x$rezultat.niewazne,x$rezultat.lista,xlim = c(0,1),ylim=c(0,1),colramp = Lab.palette,nrpoints=0)
smoothScatter(x$frekwencja,x$rezultat.niewazne,xlim = c(0,1),ylim=c(0,1))

### try with lattice ####

library(lattice)
levelplot(t.nstations)
# niezbyt
dfgminy$f.freq <- cut(dfgminy$frekwencja,breaks=xlx,right=TRUE,labels=FALSE)/(length(xlx)-1)
dfgminy$f.rezultat.lista <- cut(dfgminy$rezultat.lista,breaks=xlx,right=TRUE,labels=FALSE)/(length(xlx)-1)
levelplot(glosy~f.freq*f.rezultat.lista|shortlista,data=dfgminy,row.values=xlx,column.values=xlx,col.regions = my.palette)
# co to za kreski? z wygładzania?

# jak w raporcie http://samarcandanalytics.com/?page_id=39 - analiza votes/eligible ####
# (w koncu nie uzyte)

rm(list=ls())
load("data.Rda")

dfgminy <- dfgminy[dfgminy$uprawnieni>=100,]

f1<-hist(dfgminy$frekwencja[dfgminy$lp==1],breaks = 100,plot=FALSE)
f2<-hist(dfgminy$frek2[dfgminy$lp==1],breaks = 100,plot=FALSE)

plot(f2$breaks[-1],f2$counts,type="s",col="blue",lwd=2,main="Rozkład głosów oddanych i waznych",ylab="Liczba obwodów",xlab="")
lines(f1$breaks[-1],f1$counts,type="s",col="red",lwd=2)
legend(x=0,y=1500,fill=c("blue","red"),legend = c("Głosy ważne/Uprawnieni","Głosy oddane/Uprawnieni"),bty="n",cex=0.8)

library(lattice)

stopka<-function() {
        trellis.focus("toplevel")
        panel.text(0.85,0.02,"http://niepewnesondaze.blogspot.com",col="gray")
        trellis.unfocus()
}

xyplot(ve~frekwencja|shortlista,data=dfgminy[dfgminy$shortlista %in% listy,],col="#ffaa1140",pch=".",
       xlab="Frekwencja",ylab="Poparcie dla listy",xlim=c(0,1),ylim=c(0,1),
       main="Wyniki list w obwodach",
       panel=function(x,y,...) { 
               panel.xyplot(x,y,...);
               panel.lmline(x,y,col="black");
               panel.loess(x,y,col="red");
#               panel.abline(h=5,col="gray")
       }
       )
stopka()

xyplot(ve~frekwencja|woj,data=dfgminy[dfgminy$shortlista=="Duda",],col="#ffaa1140",pch=".",
       xlab="Frekwencja",ylab="Poparcie dla listy",xlim=c(0,1),ylim=c(0,1),
       main="Wyniki list w obwodach",
       panel=function(x,y,...) { 
               panel.xyplot(x,y,...);
               panel.lmline(x,y,col="black");
               panel.loess(x,y,col="red");
               #               panel.abline(h=5,col="gray")
       }
)
stopka()

## zaleznosc wyniku partii od liczby głosów nieważnych ####

rm(list=ls())
load("data.Rda")
dfgminy$niewazne.wydane <- dfgminy$glosyniewazne/dfgminy$kartywydane
dfgminy$niewazne.uprawnieni <- dfgminy$glosyniewazne/dfgminy$uprawnieni
xyplot(rezultat.lista~niewazne.wydane|shortlista,data=dfgminy[dfgminy$shortlista %in% listy,],col="#ffaa1140",pch=".",
       xlab="Głosy nieważne/Wydane karty",ylab="Poparcie dla listy",xlim=c(0,.1),ylim=c(0,1),
       main="Wyniki list w obwodach",
       panel=function(x,y,...) { 
               panel.xyplot(x,y,...);
               panel.lmline(x,y,col="black");
               #panel.loess(x,y,col="red");
       }
)
stopka()

fit.po<-lm(rezultat.lista~niewazne.wydane,data=dfgminy[dfgminy$shortlista=="Komorowski",])
fit.pis<-lm(rezultat.lista~niewazne.wydane,data=dfgminy[dfgminy$shortlista=="Duda",])
fit.po
confint(fit.po)
confint(fit.pis)

xyplot(niewazne.wydane~frekwencja,data=dfgminy[dfgminy$shortlista=="Komorowski",],pch=".",col=kolory[1],
       panel=function(x,y,...) {
               panel.xyplot(x,y,...);
               panel.lmline(x,y,col="black");
#               panel.loess(x,y,col="red");
       })

fit.nw<-lm(niewazne.wydane~frekwencja,data=dfgminy[dfgminy$shortlista=="Komorowski" & dfgminy$niewazne.wydane>0,])
confint(fit.nw)

# pomysl2:
# Jako, że w ostatnich wyborach była ogromna liczba nieważnch głosów to proponuję im się przyjrzeć. Czy myślisz, że korelacja odsetka nieważnych głosów do poparcia mogłąby coś wykazać? Będę wdzięczny za odpowiedź.
