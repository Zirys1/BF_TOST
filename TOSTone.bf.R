## example at the bottom.


TOSTone.bf<-function(m,mu,sd,n,low_eqbound_d, high_eqbound_d, alpha, prior_dist, effect_prior, se_prior, df_prior, uniform_lower_bound, uniform_upper_bound, plot = TRUE){
  if(missing(alpha)) {
    alpha<-0.05
  }
  # Calculate TOST, t-test, 90% CIs and 95% CIs
  low_eqbound<-low_eqbound_d*sd
  high_eqbound<-high_eqbound_d*sd
  degree_f<-n-1
  t1<-(m-mu-low_eqbound)/(sd/sqrt(n))# t-test
  p1<-pt(t1, degree_f, lower.tail=FALSE)
  t2<-(m-mu-high_eqbound)/(sd/sqrt(n)) #t-test
  p2<-pt(t2, degree_f, lower.tail=TRUE)
  t<-(m-mu)/(sd/sqrt(n))
  pttest<-2*pt(-abs(t), df=degree_f)
  LL90<-(m-mu)-qt(1-alpha, degree_f)*(sd/sqrt(n))
  UL90<-(m-mu)+qt(1-alpha, degree_f)*(sd/sqrt(n))
  LL95<-(m-mu)-qt(1-(alpha/2), degree_f)*(sd/sqrt(n))
  UL95<-(m-mu)+qt(1-(alpha/2), degree_f)*(sd/sqrt(n))
  ptost<-max(p1,p2) #Get highest p-value for summary TOST result
  ttost<-ifelse(abs(t1) < abs(t2), t1, t2) #Get lowest t-value for summary TOST result
  dif<-(m-mu)
  testoutcome<-ifelse(pttest<alpha,"significant","non-significant")
  TOSToutcome<-ifelse(ptost<alpha,"significant","non-significant")

  # Plot results
  if (plot == TRUE) {
  plot(NA, ylim=c(0,1), xlim=c(min(LL95,low_eqbound,dif)-max(UL95-LL95, high_eqbound-low_eqbound,dif)/10, max(UL95,high_eqbound,dif)+max(UL95-LL95, high_eqbound-low_eqbound, dif)/10), bty="l", yaxt="n", ylab="",xlab="Mean Difference")
  points(x=dif, y=0.5, pch=15, cex=2)
  abline(v=high_eqbound, lty=2)
  abline(v=low_eqbound, lty=2)
  abline(v=0, lty=2, col="grey")
  segments(LL90,0.5,UL90,0.5, lwd=3)
  segments(LL95,0.5,UL95,0.5, lwd=1)
  title(main=paste("Equivalence bounds ",round(low_eqbound,digits=3)," and ",round(high_eqbound,digits=3),"\nMean difference = ",round(dif,digits=3)," \n TOST: ", 100*(1-alpha*2),"% CI [",round(LL90,digits=3),";",round(UL90,digits=3),"] ", TOSToutcome," \n NHST: ", 100*(1-alpha),"% CI [",round(LL95,digits=3),";",round(UL95,digits=3),"] ", testoutcome,sep=""), cex.main=1)
  }

  # Print TOST and t-test results in message form
  message(cat("Using alpha = ",alpha," the NHST one-sample t-test was ",testoutcome,", t(",degree_f,") = ",t,", p = ",pttest,sep=""))
  cat("\n")
  message(cat("Using alpha = ",alpha," the equivalence test was ",TOSToutcome,", t(",degree_f,") = ",ttost,", p = ",ptost,sep=""))

  # Print TOST and t-test results in table form
  TOSTresults<-data.frame(t1,p1,t2,p2,degree_f)
  colnames(TOSTresults) <- c("t-value 1","p-value 1","t-value 2","p-value 2","df")
  bound_d_results<-data.frame(low_eqbound_d,high_eqbound_d)
  colnames(bound_d_results) <- c("low bound d","high bound d")
  bound_results<-data.frame(low_eqbound,high_eqbound)
  colnames(bound_results) <- c("low bound raw","high bound raw")
  CIresults<-data.frame(LL90,UL90)
  colnames(CIresults) <- c(paste("Lower Limit ",100*(1-alpha*2),"% CI raw",sep=""),paste("Upper Limit ",100*(1-alpha*2),"% CI raw",sep=""))
  cat("TOST results:\n")
  print(TOSTresults)
  cat("\n")
  cat("Equivalence bounds (Cohen's d):\n")
  print(bound_d_results)
  cat("\n")
  cat("Equivalence bounds (raw scores):\n")
  print(bound_results)
  cat("\n")
  cat("TOST confidence interval:\n")
  print(CIresults)
  #below added BF calc
  bayes<-TRUE #expect to provide bayes
  if(missing(prior_dist)) {
    bayes<-FALSE #if no prior effect size is provided, BF not calculated
  }
  if(bayes==TRUE){
    if(prior_dist=="normal"){
      if(missing(se_prior)){
        se_prior<-effect_prior/2 #if not specified otherwise, default SE is effect/2
      }
    }
    if(prior_dist=="halfnormal"){
      if(missing(se_prior)){
        se_prior<-effect_prior #if not specified otherwise, default SE is effect
        effect_prior<-0 #halfnormal is centered on 0
      } }
    if(prior_dist=="cauchy"){
      df_prior<-1
      if(missing(se_prior)){
        df_prior<-1
        se_prior<-effect_prior/2} #if not specified otherwise, default SE is effect
    }
    if(prior_dist=="halfcauchy"){
      df_prior<-1
      if(missing(se_prior)){
        df_prior<-1
        se_prior<-effect_prior #if not specified otherwise, default SE is effect
        effect_prior<-0 #halfcauchy is centered on 0
      }
    }
    if(missing(df_prior)){
      df_prior<-1000 #if not specified otherwise, default df = 100000 (practically normal)
    }
    if(prior_dist=="uniform"){
      theta = ((uniform_upper_bound + uniform_lower_bound)/2) - (2 * (uniform_upper_bound - uniform_lower_bound))
      tLL <- ((uniform_upper_bound + uniform_lower_bound)/2) - (2 * (uniform_upper_bound - uniform_lower_bound))
      tUL <- ((uniform_upper_bound + uniform_lower_bound)/2) + (2 * (uniform_upper_bound - uniform_lower_bound))
      incr <- (tUL - tLL) / 4000
      theta=seq(from = theta, by = incr, length = 4001)
      dist_theta = numeric(4001)
      dist_theta[theta >= uniform_lower_bound & theta <= uniform_upper_bound] = 1
      bayes_summary <- data.frame(prior_dist, uniform_lower_bound, uniform_upper_bound)
      colnames(bayes_summary) <- c("Prior Distribution","Lower Bound","Upper Bound")
    } else {
      theta <- effect_prior - 10 * se_prior
      incr <- se_prior / 200
      theta=seq(from = effect_prior - 10 * se_prior, by = incr, length = 4001)
      dist_theta <- dt(x = (theta-effect_prior)/se_prior, df=df_prior)
      bayes_summary <- data.frame(prior_dist, effect_prior, se_prior, df_prior)
      colnames(bayes_summary) <- c("Prior Distribution","Effect Size Prior","SE Prior", "df Prior")
      if(prior_dist=="halfnormal"){
        dist_theta[theta <= 0] = 0
      }
      if(prior_dist=="halfcauchy"){
        dist_theta[theta <= 0] = 0
      }
    }
    dist_theta_alt = dist_theta/sum(dist_theta)
    likelihood <- dt((dif-theta)/(dif/t), df = degree_f) #use dif - can be set to d Create likelihood, for each theta, compute how well it predicts the obtained mean, given the obtained SEM and the obtained dfs.
    likelihood_alt = likelihood/sum(likelihood) # alternative computation with normalized vectors
    height <- dist_theta * likelihood # Multiply prior with likelihood, this gives the unstandardized posterior
    area <- sum(height * incr)
    normarea <- sum(dist_theta * incr)
    height_alt = dist_theta_alt * likelihood_alt
    height_alt = height_alt/sum(height_alt)
    LikelihoodTheory <- area/normarea
    LikelihoodNull <- dt(dif/(dif/t), df = degree_f)
    BayesFactor <- round(LikelihoodTheory / LikelihoodNull, 6)
    bayes_results <- data.frame(BayesFactor, LikelihoodTheory, LikelihoodNull)
    colnames(bayes_results) <- c("Bayes Factor","Likelihood (alternative)","Likelihood (null)")
    cat("Bayes Results:\n")
    print(bayes_results)
    cat("\n")
    cat("Bayes Summary:\n")
    print(bayes_summary)
    cat("\n")
    invisible(list(TOST_t1=t1,TOST_p1=p1,TOST_t2=t2,TOST_p2=p2, TOST_df=degree_f,alpha=alpha,low_eqbound=low_eqbound,high_eqbound=high_eqbound,low_eqbound=low_eqbound,high_eqbound=high_eqbound, LL_CI_TOST=LL90,UL_CI_TOST=UL90,bf=BayesFactor, ll_theory=LikelihoodTheory, ll_null=LikelihoodNull))
  }
  #plot (adapted from Wiens by DL)
  myminY = 1
  # rescale prior and posterior to sum = 1 (density)
  dist_theta_alt = dist_theta_alt / (sum(dist_theta_alt)*incr)
  height_alt = height_alt/(sum(height_alt)*incr)
  # rescale likelood to maximum = 1
  likelihood_alt = likelihood_alt / max(likelihood_alt)
  data = cbind(dist_theta_alt, height_alt)
  maxy = max(data)
  max_per_x = apply(data,1,max)
  max_x_keep = max_per_x/maxy*100 > myminY  # threshold (1%) here
  x_keep = which(max_x_keep==1)
  #png(file=paste("Fig1.png",sep=""),width=2300,height=2000, units = "px", res = 300)
  plot(NA, ylim=c(0,maxy), xlim=c(min(LL90,low_eqbound)-max(UL90-LL90, high_eqbound-low_eqbound)/5, max(UL90,high_eqbound)+max(UL90-LL90, high_eqbound-low_eqbound)/5), bty="l", yaxt="n", ylab="",xlab="Mean Difference")
  points(x=dif, y=maxy/2, pch=15, cex=2)
  abline(v=high_eqbound, lty=2)
  abline(v=low_eqbound, lty=2)
  abline(v=0, lty=2, col="grey")
  segments(LL90,maxy/2,UL90,maxy/2, lwd=3)
  segments(LL95,maxy/2,UL95,maxy/2, lwd=1)
  if(bayes==FALSE) {
    title(main=paste("Equivalence bounds ",round(low_eqbound,digits=3)," and ",round(high_eqbound,digits=3),"\nMean difference = ",round(dif,digits=3)," \n TOST: ", 100*(1-alpha*2),"% CI [",round(LL90,digits=3),";",round(UL90,digits=3),"] ", TOSToutcome," \n NHST: ", 100*(1-alpha),"% CI [",round(LL95,digits=3),";",round(UL95,digits=3),"] ", testoutcome, sep=""), cex.main=1)
  }
  if(bayes==TRUE){
    par(new=TRUE)
    plot(theta, dist_theta_alt, type = "l",
         ylim = c(0, maxy),
         xlim=c(min(LL90,low_eqbound)-max(UL90-LL90, high_eqbound-low_eqbound)/5, max(UL90,high_eqbound)+max(UL90-LL90, high_eqbound-low_eqbound)/5),
         ylab = "Density (for Prior and Posterior)", xlab = "", col = "grey46", lwd = 2, lty = 2)
    lines(theta, height_alt, type = "l", col = "black", lwd = 3, lty = 1)
    theta0 = which(theta == min(theta[theta>0]))
    points(theta[theta0],dist_theta_alt[theta0], pch = 19, col = "grey46", cex = 1.5)
    points(theta[theta0],height_alt[theta0], pch = 19, col = "black", cex = 1.5)
    par(new = T)
    plot(theta, likelihood_alt, type = "l",
         ylim = c(0, 1),
         xlim=c(min(LL90,low_eqbound)-max(UL90-LL90, high_eqbound-low_eqbound)/5, max(UL90,high_eqbound)+max(UL90-LL90, high_eqbound-low_eqbound)/5),     col = "dodgerblue", lwd = 2, lty = 3, axes = F, xlab = NA, ylab = NA)
    axis(side = 4)
    mtext(side = 4, line = 3, 'Likelihood')
    abline(v = theta[theta0], lwd = 2, lty = 3)
    if(bayes==TRUE){
      title(main=paste("Bounds ",round(low_eqbound,digits=3)," and ",round(high_eqbound,digits=3),", Mean difference = ",round(dif,digits=3)," \n TOST: ", 100*(1-alpha*2),"% CI [",round(LL90,digits=3),";",round(UL90,digits=3),"] ", TOSToutcome," \n NHST: ", 100*(1-alpha),"% CI [",round(LL95,digits=3),";",round(UL95,digits=3),"] ", testoutcome,"\n Bayes Factor = ", BayesFactor, sep=""), cex.main=1)
    }
  }
}


TOSTone.bf(m = 0.06,
           mu = 0,
           sd = 1.01,
           n = 500,
           low_eqbound_d = -0.1,
           high_eqbound_d = 0.1, 
           prior_dist = "halfnormal", 
           effect_prior = 0,
           se_prior = 0.2,
           df_prior = 1000)