#' Perform test on two repeated measures
#'
#' Test based on Hotelling's T squared for the null hypothesis of no effect
#' between two repeated measures (e.g., treatment/control)
#'
#' The function assumes that each individual observation (e.g., specimen) has been measured two times
#' (e.g., at two time points, or between two treatments).
#'
#' If rnames is TRUE (default), the rownames of the matrix or the names along
#' the 3rd dimension (for arrays) will be used to match the order of observations (e.g., specimens)
#' between the two datasets. Otherwise, the function will assume that the observations in T1 and T2
#' are in the same order.
#'
#' This function is useful in various contexts, such as:
#'  \itemize{
#'   \item testing the effect of preservation (Fruciano et al. 2020)
#'   \item testing for variation through time
#' }
#'
#' For instance, in the context of the effect of preservation on geometric morphometrics,
#' it has been argued (Fruciano, 2016) that various studies have improperly used on repeated measures data
#' methods developed for independent observations, and this can lead to incorrect inference.
#'
#' @section Notice:
#' The function requires internally non-singular matrices
#' (for instance, number of cases should be larger than the number of variables).
#' One solution can be to perform a principal component analysis and use the scores
#' for all the axes with non-zero and non-near-zero eigenvalues.
#' To overcome some situations where a singular matrix can occurr, the function can
#' use internally a shrinkage estimator of the covariance matrix (Ledoit & Wolf 2004).
#' This is called setting shrink = TRUE.
#' However, in this case, the package nlshrink should have been installed.
#' Also, notice that if the matrices T1 and T2 are provided as arrays, this requires
#' the package Morpho to be installed.
#'
#' @param T1,T2 matrices (n x p of n observation for p variables)
#' or arrays (t x p x n of n observations, t landmarks in p dimensions),
#' @param rnames if TRUE (default) the rownames of the matrix or the names along
#' the 3rd dimension (for arrays) will be used to match the order
#' @param shrink if TRUE, a shrinkage estimator of covariance is used internally
#' @return The function outputs a matrix n x p of the original data projected
#' to the subspace orthogonal to the vector
#'
#' @section Citation:
#' If you use this function please cite Fruciano et al. 2020
#'
#' @references Fruciano C. 2016. Measurement error in geometric morphometrics. Development Genes and Evolution 226:139-158.
#' @references Fruciano C., Schmidt, I., Ramirez Sanchez, M.M., Morek, W., Avila Valle, Z.A., Talijancic, I., Pecoraro, C., Schermann Legionnet, A. 2020. Tissue preservation can affect geometric morphometric analyses: a case study using fish body shape. Zoological Journal of the Linnean Society 188:148-162.
#' @references Ledoit O, Wolf M. 2004. A well-conditioned estimator for large-dimensional covariance matrices. Journal of Multivariate Analysis 88:365-411.
#'
#' @import stats
#' @export
repeated_measures_test=function(T1, T2, rnames=TRUE, shrink=FALSE) {
	if ("array" %in% class(T1) && length(dim(T1))==3) {
		T1=Morpho::vecx(T1)
			}
	if ("array" %in% class(T2) && length(dim(T1))==3) {
		T2=Morpho::vecx(T2)
			}
	# If an array, transform in a 2D matrix
	if (rnames==TRUE) {
	T2=T2[rownames(T1),]
	warning("The names of the observations in the two datasets will be used for matching them")
	} else {
	warning("Names are not used, the observations will be assumed to be in the same order")
	}
	# If rnames is TRUE, reorder the second array
	# based on the rownames of the first array
	if (nrow(T1)!=nrow(T2)) {
	stop(paste("The two sets have different number of rows (observations)"))
	}
	if (ncol(T1)!=ncol(T2)) {
	stop(paste("The two sets have different number of columns (variables)"))
	}
	if (nrow(T1)<=ncol(T1)) {
			warning('Number of cases less or equal to the number of variables')
			}
	ObsEuclideandD=dist(rbind(colMeans(T1),colMeans(T2)))
	ObsPairedT2=HotellingT2p(T1,T2, shrink=shrink)
	# Compute  Euclidean distances between the two treatments and
	# paired Hotteling T squared from one observation
	# in one treatment and the same observation in the second treatment
	Results=c(ObsEuclideandD,
			ObsPairedT2$HottelingT2,
			ObsPairedT2$Fstat,
			ObsPairedT2$p_value
			)
	names(Results)=c("EuclideanD",
					"HotellingT2",
					"Fstat",
					"p_value"
				)
return(Results)
}



# Function to compute Hotteling T squared
# with repeated measures data
# (not exported)
HotellingT2p=function(A1, A2, shrink=FALSE) {
	D=A2-A1
	Di=colMeans(D)
	if (shrink==TRUE) {
	  S=nlshrink::linshrink_cov(D)
	} else {
	  S=cov(D)
	}
	n=nrow(A1)
	p=ncol(A1)
	df2=n-p
	pT2=n*rbind(Di)%*%solve(S)%*%cbind(Di)
		if (n<=p) {
			Fstat=NA
			pval=NA
			# warning('More variables than cases,
			# no F statistic nor p-value will be computed')
			} else {
	Fstat = pT2 / (p * (n-1) / df2)
	pval = 1 - pf(Fstat, df1=p, df2=df2)
		}
Results=list(HottelingT2=pT2,
				Fstat=Fstat,
				p_value=pval)

return(Results)
}

