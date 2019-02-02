#include "rand_custom.h"

#include "utils.h"

#include "convert_seed.h"
#include <stdexcept>
#include <sstream>

pcg32 create_pcg32(SEXP seed, int stream) {
    return pcg32(convert_seed<uint64_t>(seed), stream);
}

void check_pcg_vectors(const Rcpp::List seeds, Rcpp::IntegerVector streams, size_t N, const char* msg) {
    if (static_cast<size_t>(seeds.size())!=N) {
        std::stringstream err;
        err << "number of " << msg << " and seeds should be the same";
        throw std::runtime_error(err.str());
    }

    if (static_cast<size_t>(streams.size())!=N) {
        std::stringstream err;
        err << "number of " << msg << " and streams should be the same";
        throw std::runtime_error(err.str());
    }

    return;
}
