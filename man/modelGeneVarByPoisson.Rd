% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/modelGeneVarByPoisson.R
\name{modelGeneVarByPoisson}
\alias{modelGeneVarByPoisson}
\alias{modelGeneVarByPoisson,ANY-method}
\alias{modelGeneVarByPoisson,SummarizedExperiment-method}
\alias{modelGeneVarByPoisson,SingleCellExperiment-method}
\title{Model the per-gene variance with Poisson noise}
\usage{
modelGeneVarByPoisson(x, ...)

\S4method{modelGeneVarByPoisson}{ANY}(
  x,
  size.factors = NULL,
  block = NULL,
  design = NULL,
  subset.row = NULL,
  npts = 1000,
  dispersion = 0,
  pseudo.count = 1,
  ...,
  equiweight = TRUE,
  method = "fisher",
  BPPARAM = SerialParam()
)

\S4method{modelGeneVarByPoisson}{SummarizedExperiment}(x, ..., assay.type = "counts")

\S4method{modelGeneVarByPoisson}{SingleCellExperiment}(x, size.factors = sizeFactors(x), ...)
}
\arguments{
\item{x}{A numeric matrix of counts where rows are (usually endogenous) genes and columns are cells.

Alternatively, a \linkS4class{SummarizedExperiment} or \linkS4class{SingleCellExperiment} containing such a matrix.}

\item{...}{For the generic, further arguments to pass to each method.

For the ANY method, further arguments to pass to \code{\link{fitTrendVar}}.

For the \linkS4class{SummarizedExperiment} method, further arguments to pass to the ANY method.

For the \linkS4class{SingleCellExperiment} method, further arguments to pass to the SummarizedExperiment method.}

\item{size.factors}{A numeric vector of size factors for each cell in \code{x}, to be used for scaling gene expression.}

\item{block}{A factor specifying the blocking levels for each cell in \code{x}.
If specified, variance modelling is performed separately within each block and statistics are combined across blocks.}

\item{design}{A numeric matrix containing blocking terms for uninteresting factors of variation.}

\item{subset.row}{See \code{?"\link{scran-gene-selection}"}, specifying the rows for which to model the variance.
Defaults to all genes in \code{x}.}

\item{npts}{An integer scalar specifying the number of interpolation points to use.}

\item{dispersion}{A numeric scalar specifying the dispersion for the NB distribution.
If zero, a Poisson distribution is used.}

\item{pseudo.count}{Numeric scalar specifying the pseudo-count to add prior to log-transformation.}

\item{equiweight}{A logical scalar indicating whether statistics from each block should be given equal weight.
Otherwise, each block is weighted according to its number of cells.
Only used if \code{block} is specified.}

\item{method}{String specifying how p-values should be combined when \code{block} is specified, see \code{\link{combinePValues}}.}

\item{BPPARAM}{A \linkS4class{BiocParallelParam} object indicating whether parallelization should be performed across genes.}

\item{assay.type}{String or integer scalar specifying the assay containing the log-expression values.}
}
\value{
A \linkS4class{DataFrame} is returned where each row corresponds to a gene in \code{x} (or in \code{subset.row}, if specified).
This contains the numeric fields:
\describe{
\item{\code{mean}:}{Mean normalized log-expression per gene.}
\item{\code{total}:}{Variance of the normalized log-expression per gene.}
\item{\code{bio}:}{Biological component of the variance.}
\item{\code{tech}:}{Technical component of the variance.}
\item{\code{p.value, FDR}:}{Raw and adjusted p-values for the test against the null hypothesis that \code{bio<=0}.}
}

If \code{block} is not specified, 
the \code{metadata} of the DataFrame contains the output of running \code{\link{fitTrendVar}} on the simulated counts,
along with the \code{mean} and \code{var} used to fit the trend.

If \code{block} is specified, the output contains another \code{per.block} field.
This field is itself a DataFrame of DataFrames, where each internal DataFrame contains statistics for the variance modelling within each block and has the same format as described above. 
Each internal DataFrame's \code{metadata} contains the output of \code{\link{fitTrendVar}} for the cells of that block.
}
\description{
Model the variance of the log-expression profiles for each gene, 
decomposing it into technical and biological components based on a mean-variance trend corresponding to Poisson noise.
}
\details{
For each gene, we compute the variance and mean of the log-expression values.
A trend is fitted to the variance against the mean for simulated Poisson counts as described in \code{\link{fitTrendPoisson}}.
The technical component for each gene is defined as the value of the trend at that gene's mean abundance.
The biological component is then defined as the residual from the trend.

This function is similar to \code{\link{modelGeneVarWithSpikes}}, with the only difference being that the trend is fitted on simulated Poisson count-derived variances rather than spike-ins.
The assumption is that the technical component is Poisson-distributed, or at least negative binomial-distributed with a known constant dispersion.
This is useful for UMI count data sets that do not have spike-ins and are too heterogeneous to assume that most genes exhibit negligible biological variability.

If no size factors are supplied, they are automatically computed depending on the input type:
\itemize{
\item If \code{size.factors=NULL} for the ANY method, the sum of counts for each cell in \code{x} is used to compute a size factor via the \code{\link{librarySizeFactors}} function.
\item If \code{size.factors=NULL} for the \linkS4class{SingleCellExperiment} method, \code{\link{sizeFactors}(x)} is used if available.
Otherwise, it defaults to library size-derived size factors.
}
If \code{size.factors} are supplied, they will override any size factors present in \code{x}.
}
\section{Computing p-values}{

The p-value for each gene is computed by assuming that the variance estimates are normally distributed around the trend, and that the standard deviation of the variance distribution is proportional to the value of the trend.
This is used to construct a one-sided test for each gene based on its \code{bio}, under the null hypothesis that the biological component is equal to zero.
The proportionality constant for the standard deviation is set to the \code{std.dev} returned by \code{\link{fitTrendVar}}.
This is estimated from the spread of variance estimates for the simulated Poisson-distributed counts, so the null hypothesis effectively becomes \dQuote{is this gene \emph{more} variable than a hypothetical gene with only Poisson noise?}
}

\section{Handling uninteresting factors}{

Setting \code{block} will estimate the mean and variance of each gene for cells in each level of \code{block} separately.
The trend is fitted separately for each level, and the variance decomposition is also performed separately.
Per-level statistics are then combined to obtain a single value per gene:
\itemize{
\item For means and variance components, this is done by averaging values across levels.
If \code{equiweight=FALSE}, a weighted average is used where the value for each level is weighted by the number of cells.
By default, all levels are equally weighted when combining statistics.
\item Per-level p-values are combined using \code{\link{combinePValues}} according to \code{method}.
By default, Fisher's method is used to identify genes that are highly variable in any batch.
Whether or not this is responsive to \code{equiweight} depends on the chosen method.
\item Blocks with fewer than 2 cells are completely ignored and do not contribute to the combined mean, variance component or p-value.
}

Use of \code{block} is the recommended approach for accounting for any uninteresting categorical factor of variation.
In addition to accounting for systematic differences in expression between levels of the blocking factor,
it also accommodates differences in the mean-variance relationships.

Alternatively, uninteresting factors can be used to construct a design matrix to pass to the function via \code{design}.
In this case, a linear model is fitted to the expression profile for each gene and the residual variance is calculated.
This approach is useful for covariates or additive models that cannot be expressed as a one-way layout for use in \code{block}.
However, it assumes that the error is normally distributed with equal variance for all observations of a given gene.

Use of \code{block} and \code{design} together is currently not supported and will lead to an error.
}

\examples{
library(scuttle)
sce <- mockSCE()

# Using spike-ins.
pois <- modelGeneVarByPoisson(sce)
pois

plot(pois$mean, pois$total, ylim=c(0, 10))
points(metadata(pois)$mean, metadata(pois)$var, col="red", pch=16)
curve(metadata(pois)$trend(x), add=TRUE, col="dodgerblue")

# With blocking.
block <- sample(LETTERS[1:2], ncol(sce), replace=TRUE)
blk <- modelGeneVarByPoisson(sce, block=block)
blk

par(mfrow=c(1,2))
for (i in colnames(blk$per.block)) {
    current <- blk$per.block[[i]]
    plot(current$mean, current$total, ylim=c(0, 10))
    points(metadata(current)$mean, metadata(current)$var, col="red", pch=16)
    curve(metadata(current)$trend(x), add=TRUE, col="dodgerblue")
}

}
\seealso{
\code{\link{fitTrendVar}}, for the trend fitting options.

\code{\link{modelGeneVar}}, for modelling variance without spike-in controls.
}
\author{
Aaron Lun
}
