
//typedef unsigned int uint32;
//#define UINT32_MAX UINT_MAX

// https://en.wikipedia.org/wiki/Xorshift
typedef struct _xorshift32_state {
    unsigned a;
} xorshift32_state;

/* The state word must be initialized to non-zero */
inline unsigned xorshift32(xorshift32_state *pState)
{
    /* Algorithm "xor" from p. 4 of Marsaglia, "Xorshift RNGs" */
    unsigned x = pState->a;
    x ^= x << 13;
    x ^= x >> 17;
    x ^= x << 5;
    return pState->a = x;
}

inline float rand_real(float min, float max, xorshift32_state* pState)
{
    return min + (max - min) * (float)xorshift32(pState) / (float)UINT_MAX;
}

typedef struct {
    global unsigned char* data;
    size_t N, M;
    float beta;
} PackedLattice;

// periodic index
inline int pb(int i, int N) {
    if (i < 0)
        return (N + (i % N)) % N;

    return i % N;
}

inline bool getSpin(int i, int j, PackedLattice* pLattice)
{
    i = pb(i, pLattice->N);
    j = pb(j, pLattice->M);
    const size_t index = i * pLattice->M + j;
    const size_t char_index = index / 8;
    const size_t bit_index = index % 8;
    return (pLattice->data[char_index] >> bit_index) & 1;
}

inline void setSpin(size_t i, size_t j, bool spin, PackedLattice* pLattice)
{
    const size_t index = i * pLattice->M + j;
    const size_t char_index = index / 8;
    const size_t bit_index = index % 8;
    if (spin)
        pLattice->data[char_index] |= 1 << bit_index;
    else
        pLattice->data[char_index] &= ~(1 << bit_index);
}

inline void setToWithProbability(int i, int j, bool value, float p, PackedLattice* pLattice, xorshift32_state* pState)
{
    if (rand_real(0.0f, 1.0f, pState) < p)
        setSpin(i, j, value, pLattice);
}

inline void flipWithProbability(int i, int j, float p, PackedLattice* pLattice, xorshift32_state* pState)
{
    bool spin = getSpin(i, j, pLattice);
    setToWithProbability(i, j, !spin, p, pLattice, pState);
}

void metro_step_impl(PackedLattice* pLattice, int parity, xorshift32_state* pState)
{
    size_t id = get_global_id(0);

    for (size_t k = 0; k < 8; ++k)
    {
        const size_t pt_index = id * 8 + k;
        const size_t i = pt_index / pLattice->M;
        const size_t j = pt_index % pLattice->M;

        if (i >= pLattice->N || j >= pLattice->M)
            continue;

        if ((i + j) % 2 != parity)
            continue;

        if (!(rand_real(0, 1, pState) < 1.59))
            continue;

        // !!!
        //setSpin(i, j, rand_real(0, 1, &state) < 0.25, lattice, N, M);
        //continue;

        const bool spin_bool = getSpin(i, j, pLattice);
        const int spin = spin_bool ? 1 : -1;

        int neighbors = 0;
        neighbors += getSpin(i - 1, j, pLattice) ? 1 : -1;
        neighbors += getSpin(i + 1, j, pLattice) ? 1 : -1;
        neighbors += getSpin(i, j - 1, pLattice) ? 1 : -1;
        neighbors += getSpin(i, j + 1, pLattice) ? 1 : -1;

        const float p = exp(-2.f * pLattice->beta * spin * neighbors);

        //if (rand_real(0, 1, &state) < p)
        //    setSpin(i, j, !spin_bool, lattice, N, M);
        flipWithProbability(i, j, p, pLattice, pState);

        //for (int i = 0; i < 32; ++i)
        //    xorshift32(&state);

        //lattice[(i * M + j) / 8] = pt_index % 2;
        //setSpin(i, j, (i + j) % 2, lattice, N, M);
        //setSpin(i, j, rand_real(0, 1, &state) < 0.25f, lattice, N, M);
    }
}

//xorshift32_state state;
void kernel metro_step(
    global unsigned char* pLatticeData,
    global const unsigned* rand_seeds,
    unsigned N,
    unsigned M,
    const float beta,
    int parity
) {
    const size_t id = get_global_id(0);

    PackedLattice lattice;
    lattice.data = pLatticeData;
    lattice.N = N;
    lattice.M = M;
    lattice.beta = beta;
    //lattice.beta = 0.6;

    // init rand seed
    xorshift32_state state;
    // set the random seed based on the global id
    // we use id*id because id seems to be a bit too regular
    // TODO: use a better seed
    unsigned initializer_combo = id*id + 1;
    //state.a = id + 1;
    state.a = 0;
    for (int b = 0; b < 32; ++b)
        if (initializer_combo & (1 << b))
            state.a ^= rand_seeds[b];
    //return;
    for (int i = 0; i < 0; ++i)
        xorshift32(&state);

    //lattice[get_global_id(0)] = (unsigned char)(rand_real(0, 1) < 0.5f) ? 0u : 1u;

    //for (int parity = 0; parity < 2; ++parity)
    {
        metro_step_impl(&lattice, parity, &state);

        //barrier(CLK_GLOBAL_MEM_FENCE);
    }

    //setSpin(i, j, rand_real(0, 1, &state) < 0.5f, lattice, N, M);
    //setSpin(i, j, true, lattice, N, M);
}