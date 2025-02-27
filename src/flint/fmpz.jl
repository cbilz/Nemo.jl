###############################################################################
#
#   fmpz.jl : BigInts
#
###############################################################################

# Copyright (c) 2009-2014: Jeff Bezanson, Stefan Karpinski, Viral B. Shah,
# and other contributors:
#
# https://github.com/JuliaLang/julia/contributors
#
# Copyright (C) 2014, 2015 William Hart
# Copyright (C) 2015, Claus Fieker
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

# do not export div and divrem
export fmpz, FlintZZ, FlintIntegerRing, parent, show, convert, hash,
       bell, isprime, fdiv, cdiv, tdiv, rem, mod, gcd, lcm, invmod,
       powermod, abs, isqrt, popcount, prevpow2, nextpow2, ndigits, dec,
       bin, oct, hex, base, one, zero, divexact, fits, sign, nbits, deepcopy,
       tdivpow2, fdivpow2, cdivpow2, flog, clog, cmpabs, clrbit!, setbit!,
       combit!, crt, divisible, divisors, prime_divisors, divisor_lenstra,
       fmodpow2, gcdinv, isprobable_prime, jacobi_symbol, kronecker_symbol,
       remove, root, size, isqrtrem, sqrtmod, trailing_zeros, divisor_sigma,
       euler_phi, fibonacci, moebius_mu, primorial, rising_factorial,
       number_of_partitions, canonical_unit, isunit, isequal, addeq!, mul!,
       issquare, sqrt, issquare_with_sqrt, next_prime, ndivrem,
       iszero, rand, rand_bits, binomial, factorial, rand_bits_prime, iroot,
       tdivrem, fdivrem, cdivrem, ntdivrem, nfdivrem, ncdivrem,
       tstbit

###############################################################################
#
#   Data type and parent methods
#
###############################################################################

parent_type(::Type{fmpz}) = FlintIntegerRing

@doc Markdown.doc"""
    parent(a::fmpz)

Returns the unique Flint integer parent object `FlintZZ`.
"""
parent(a::fmpz) = FlintZZ

elem_type(::Type{FlintIntegerRing}) = fmpz

@doc Markdown.doc"""
    base_ring(a::FlintIntegerRing)

Returns `Union{}` as this ring is not dependent on another ring.
"""
base_ring(a::FlintIntegerRing) = Union{}

@doc Markdown.doc"""
    base_ring(a::fmpz)

Returns `Union{}` as the parent ring is not dependent on another ring.
"""
base_ring(a::fmpz) = Union{}

isdomain_type(::Type{fmpz}) = true

###############################################################################
#
#   Misc.
#
###############################################################################

# `length` should return an Integer, so BigInt seems appropriate as fmpz is not <: Integer
# this method is useful in particular to enable rand(ZZ(n):ZZ(m))
function Base.length(r::StepRange{fmpz})
    n = div((r.stop - r.start) + r.step, r.step)
    isempty(r) ? zero(BigInt) : BigInt(n)
end

################################################################################
#
#   Hashing
#
################################################################################

# Similar to hash for BigInt found in julia/base

function _fmpz_is_small(a::fmpz)
   return __fmpz_is_small(a.d)
end

function _fmpz_limbs(a::fmpz)
   return __fmpz_limbs(a.d)
end

function hash_integer(a::fmpz, h::UInt)
   return _hash_integer(a.d, h)
end

function hash(a::fmpz, h::UInt)
   return hash_integer(a, h)
end

function __fmpz_is_small(a::Int)
   return (unsigned(a) >> (Sys.WORD_SIZE - 2) != 1)
end

function __fmpz_limbs(a::Int)
   if __fmpz_is_small(a)
      return Cint(0)
   end
   b = unsafe_load(convert(Ptr{Cint}, unsigned(a)<<2), 2)
   return b
end

function _hash_integer(a::Int, h::UInt)
   s::Cint = __fmpz_limbs(a)
   s == 0 && return Base.hash_integer(a, h)
   # get the pointer after the first two Cint
   d = convert(Ptr{Ptr{UInt}}, unsigned(a) << 2) + 2*sizeof(Cint)
   p = unsafe_load(d)
   b = unsafe_load(p)
   h = xor(Base.hash_uint(xor(ifelse(s < 0, -b, b), h)), h)
   for k = 2:abs(s)
      h = xor(Base.hash_uint(xor(unsafe_load(p, k), h)), h)
   end
   return h
end

###############################################################################
#
#   Basic manipulation
#
###############################################################################

function deepcopy_internal(a::fmpz, dict::IdDict)
   z = fmpz()
   ccall((:fmpz_set, libflint), Nothing, (Ref{fmpz}, Ref{fmpz}), z, a)
   return z
end

characteristic(R::FlintIntegerRing) = 0

one(R::FlintIntegerRing) = fmpz(1)

zero(R::FlintIntegerRing) = fmpz(0)

# Exists only to support Julia functionality (no guarantees)
zero(::Type{fmpz}) = fmpz(0)

@doc Markdown.doc"""
    sign(a::fmpz)

Return the sign of $a$, i.e. $+1$, $0$ or $-1$.
"""
sign(a::fmpz) = fmpz(ccall((:fmpz_sgn, libflint), Cint, (Ref{fmpz},), a))

@doc Markdown.doc"""
    fits(::Type{Int}, a::fmpz)

Return `true` if $a$ fits into an `Int`, otherwise return `false`.
"""
fits(::Type{Int}, a::fmpz) = ccall((:fmpz_fits_si, libflint), Bool,
                                   (Ref{fmpz},), a)

@doc Markdown.doc"""
    fits(::Type{UInt}, a::fmpz)

Return `true` if $a$ fits into a `UInt`, otherwise return `false`.
"""
fits(::Type{UInt}, a::fmpz) = a < 0 ? false :
              ccall((:fmpz_abs_fits_ui, libflint), Bool, (Ref{fmpz},), a)

@doc Markdown.doc"""
    size(a::fmpz)

Return the number of limbs required to store the absolute value of $a$.
"""
size(a::fmpz) = Int(ccall((:fmpz_size, libflint), Cint, (Ref{fmpz},), a))

isunit(a::fmpz) = ccall((:fmpz_is_pm1, libflint), Bool, (Ref{fmpz},), a)

iszero(a::fmpz) = ccall((:fmpz_is_zero, libflint), Bool, (Ref{fmpz},), a)

isone(a::fmpz) = ccall((:fmpz_is_one, libflint), Bool, (Ref{fmpz},), a)

@doc Markdown.doc"""
    denominator(a::fmpz)

Return the denominator of $a$ thought of as a rational. Always returns $1$.
"""
function denominator(a::fmpz)
   return fmpz(1)
end

@doc Markdown.doc"""
    numerator(a::fmpz)

Return the numerator of $a$ thought of as a rational. Always returns $a$.
"""
function numerator(a::fmpz)
   return a
end

isodd(a::fmpz)  = ccall((:fmpz_is_odd,  libflint), Cint, (Ref{fmpz},), a) % Bool
iseven(a::fmpz) = ccall((:fmpz_is_even, libflint), Cint, (Ref{fmpz},), a) % Bool

###############################################################################
#
#   AbstractString I/O
#
###############################################################################

# fmpz is allowed as a leaf, and the following code is needed by AA's api
expressify(x::fmpz; context = nothing) = x

function AbstractAlgebra.get_syntactic_sign_abs(obj::fmpz)
    return obj < 0 ? (-1, -obj) : (1, obj)
end

AbstractAlgebra.is_syntactic_one(x::fmpz) = isone(x)

AbstractAlgebra.is_syntactic_zero(x::fmpz) = iszero(x)

function AbstractAlgebra.print_obj(S::AbstractAlgebra.printer, mi::MIME,
                                               obj::fmpz, left::Int, right::Int)
   AbstractAlgebra.print_integer_string(S, mi, string(obj), left, right)
end

string(x::fmpz) = dec(x)

show(io::IO, x::fmpz) = print(io, string(x))

show(io::IO, a::FlintIntegerRing) = print(io, "Integer Ring")

needs_parentheses(x::fmpz) = false

###############################################################################
#
#   Canonicalisation
#
###############################################################################

canonical_unit(x::fmpz) = x < 0 ? fmpz(-1) : fmpz(1)

###############################################################################
#
#   Unary operators and functions, e.g. -fmpz(12), ~fmpz(12)
#
###############################################################################

function -(x::fmpz)
    z = fmpz()
    ccall((:__fmpz_neg, libflint), Nothing, (Ref{fmpz}, Ref{fmpz}), z, x)
    return z
end

function ~(x::fmpz)
    z = fmpz()
    ccall((:fmpz_complement, libflint), Nothing, (Ref{fmpz}, Ref{fmpz}), z, x)
    return z
end

function abs(x::fmpz)
    z = fmpz()
    ccall((:fmpz_abs, libflint), Nothing, (Ref{fmpz}, Ref{fmpz}), z, x)
    return z
end

floor(x::fmpz) = x

ceil(x::fmpz) = x

###############################################################################
#
#   Binary operators and functions
#
###############################################################################

# Metaprogram to define functions +, -, *, gcd, lcm,
#                                 &, |, $ (xor)

for (fJ, fC) in ((:+, :add), (:-,:sub), (:*, :mul),
                 (:&, :and), (:|, :or), (:xor, :xor))
    @eval begin
        function ($fJ)(x::fmpz, y::fmpz)
            z = fmpz()
            ccall(($(string(:fmpz_, fC)), libflint), Nothing,
                  (Ref{fmpz}, Ref{fmpz}, Ref{fmpz}), z, x, y)
            return z
        end
    end
end

# Metaprogram to define functions fdiv, cdiv, tdiv, div

for (fJ, fC) in ((:fdiv, :fdiv_q), (:cdiv, :cdiv_q), (:tdiv, :tdiv_q),
                 (:div, :fdiv_q))
    @eval begin
        function ($fJ)(x::fmpz, y::fmpz)
            iszero(y) && throw(DivideError())
            z = fmpz()
            ccall(($(string(:fmpz_, fC)), libflint), Nothing,
                  (Ref{fmpz}, Ref{fmpz}, Ref{fmpz}), z, x, y)
            return z
        end
    end
end

# N.B. we do not export the internal definition of div
# which agrees with the internal definition of AbstractAlgebra
# Here we set Base.div to a version that agrees with Base
function Base.div(x::fmpz, y::fmpz)
    iszero(y) && throw(DivideError())
    z = fmpz()
    ccall((:fmpz_tdiv_q, libflint), Nothing,
	  (Ref{fmpz}, Ref{fmpz}, Ref{fmpz}), z, x, y)
    return z
end

function divexact(x::fmpz, y::fmpz; check::Bool=true)
    iszero(y) && throw(DivideError())
    z = fmpz()
    if check
       r = fmpz()
       ccall((:fmpz_tdiv_qr, libflint), Nothing,
             (Ref{fmpz}, Ref{fmpz}, Ref{fmpz}, Ref{fmpz}), z, r, x, y)
       r != 0 && throw(ArgumentError("Not an exact division"))
    else
       ccall((:fmpz_divexact, libflint), Nothing,
                           (Ref{fmpz}, Ref{fmpz}, Ref{fmpz}), z, x, y)
    end
    return z
end

function divides(x::fmpz, y::fmpz)
   z = fmpz()
   res = ccall((:fmpz_divides, libflint), Bool,
                           (Ref{fmpz}, Ref{fmpz}, Ref{fmpz}), z, x, y)
   return res, z
end

divides(x::fmpz, y::Integer) = divides(x, fmpz(y))

function isdivisible_by(x::fmpz, y::fmpz)
   if iszero(x)
      return true
   elseif iszero(y)
      return false
   elseif iseven(y) && isodd(x)
      return false
   elseif nbits(y) > nbits(x)
      return false
   else
      flag, q = divides(x, y)
      return flag
   end
end

function isdivisible_by(x::fmpz, y::Integer)
   if iszero(x)
      return true
   elseif iszero(y)
      return false
   elseif iseven(y) && isodd(x)
      return false
   elseif ndigits(y, base=2) > nbits(x)
      return false
   else
      r = mod(x, y)
      return r == 0
   end
end

function isdivisible_by(x::Integer, y::fmpz)
   return isdivisible_by(fmpz(x), y)
end

function rem(x::fmpz, c::fmpz)
    iszero(c) && throw(DivideError())
    q = fmpz()
    r = fmpz()
    ccall((:fmpz_tdiv_qr, libflint), Nothing,
          (Ref{fmpz}, Ref{fmpz}, Ref{fmpz}, Ref{fmpz}), q, r, x, c)
    return r
end

###############################################################################
#
#   Ad hoc binary operators
#
###############################################################################

function +(x::fmpz, c::Int)
    z = fmpz()
    if c >= 0
       ccall((:fmpz_add_ui, libflint), Nothing,
             (Ref{fmpz}, Ref{fmpz}, Int), z, x, c)
    else
       ccall((:fmpz_sub_ui, libflint), Nothing,
             (Ref{fmpz}, Ref{fmpz}, Int), z, x, -c)
    end
    return z
end

+(c::Int, x::fmpz) = x + c

function -(x::fmpz, c::Int)
    z = fmpz()
    if c >= 0
       ccall((:fmpz_sub_ui, libflint), Nothing,
             (Ref{fmpz}, Ref{fmpz}, Int), z, x, c)
    else
       ccall((:fmpz_add_ui, libflint), Nothing,
             (Ref{fmpz}, Ref{fmpz}, Int), z, x, -c)
    end
    return z
end

function -(c::Int, x::fmpz)
    z = fmpz()
    if c >= 0
       ccall((:fmpz_sub_ui, libflint), Nothing,
             (Ref{fmpz}, Ref{fmpz}, Int), z, x, c)
    else
       ccall((:fmpz_add_ui, libflint), Nothing,
             (Ref{fmpz}, Ref{fmpz}, Int), z, x, -c)
    end
    ccall((:__fmpz_neg, libflint), Nothing,
          (Ref{fmpz}, Ref{fmpz}), z, z)
    return z
end

function *(x::fmpz, c::Int)
    z = fmpz()
    ccall((:fmpz_mul_si, libflint), Nothing,
          (Ref{fmpz}, Ref{fmpz}, Int), z, x, c)
    return z
end

*(c::Int, x::fmpz) = x * c

+(a::fmpz, b::Integer) = a + fmpz(b)

+(a::Integer, b::fmpz) = fmpz(a) + b

-(a::fmpz, b::Integer) = a - fmpz(b)

-(a::Integer, b::fmpz) = fmpz(a) - b

*(a::fmpz, b::Integer) = a*fmpz(b)

*(a::Integer, b::fmpz) = fmpz(a)*b

###############################################################################
#
#   Ad hoc exact division
#
###############################################################################

divexact(x::fmpz, y::Integer; check::Bool=true) = divexact(x, fmpz(y); check=check)

divexact(x::Integer, y::fmpz; check::Bool=true) = divexact(fmpz(x), y; check=check)

###############################################################################
#
#   Ad hoc division
#
###############################################################################

function tdivpow2(x::fmpz, c::Int)
    c < 0 && throw(DomainError(c, "Exponent must be non-negative"))
    z = fmpz()
    ccall((:fmpz_tdiv_q_2exp, libflint), Nothing,
          (Ref{fmpz}, Ref{fmpz}, Int), z, x, c)
    return z
end

function fdivpow2(x::fmpz, c::Int)
    c < 0 && throw(DomainError(c, "Exponent must be non-negative"))
    z = fmpz()
    ccall((:fmpz_fdiv_q_2exp, libflint), Nothing,
          (Ref{fmpz}, Ref{fmpz}, Int), z, x, c)
    return z
end

function fmodpow2(x::fmpz, c::Int)
    c < 0 && throw(DomainError(c, "Exponent must be non-negative"))
    z = fmpz()
    ccall((:fmpz_fdiv_r_2exp, libflint), Nothing,
          (Ref{fmpz}, Ref{fmpz}, Int), z, x, c)
    return z
end

function cdivpow2(x::fmpz, c::Int)
    c < 0 && throw(DomainError(c, "Exponent must be non-negative"))
    z = fmpz()
    ccall((:fmpz_cdiv_q_2exp, libflint), Nothing,
          (Ref{fmpz}, Ref{fmpz}, Int), z, x, c)
    return z
end

function tdiv(x::fmpz, c::Int)
    c == 0 && throw(DivideError())
    z = fmpz()
    ccall((:fmpz_tdiv_q_si, libflint), Nothing,
          (Ref{fmpz}, Ref{fmpz}, Int), z, x, c)
    return z
end

function fdiv(x::fmpz, c::Int)
    c == 0 && throw(DivideError())
    z = fmpz()
    ccall((:fmpz_fdiv_q_si, libflint), Nothing,
          (Ref{fmpz}, Ref{fmpz}, Int), z, x, c)
    return z
end

function cdiv(x::fmpz, c::Int)
    c == 0 && throw(DivideError())
    z = fmpz()
    ccall((:fmpz_cdiv_q_si, libflint), Nothing,
          (Ref{fmpz}, Ref{fmpz}, Int), z, x, c)
    return z
end

rem(x::Integer, y::fmpz) = rem(fmpz(x), y)

rem(x::fmpz, y::Integer) = rem(x, fmpz(y))

mod(x::Integer, y::fmpz) = mod(fmpz(x), y)

@doc Markdown.doc"""
    mod(x::fmpz, y::Integer)

Return the remainder after division of $x$ by $y$. The remainder will be
closer to zero than $y$ and have the same sign, or it will be zero.
"""
mod(x::fmpz, y::Integer) = mod(x, fmpz(y))

div(x::Integer, y::fmpz) = div(fmpz(x), y)

# Note Base.div is different to Nemo.div
Base.div(x::Integer, y::fmpz) = Base.div(fmpz(x), y)

div(x::fmpz, y::Integer) = div(x, fmpz(y))

# Note Base.div is different to Nemo.div
Base.div(x::fmpz, y::Integer) = Base.div(x, fmpz(y))

divrem(x::fmpz, y::Integer) = divrem(x, fmpz(y))

divrem(x::Integer, y::fmpz) = divrem(fmpz(x), y)

###############################################################################
#
#   Division with remainder
#
###############################################################################

function divrem(x::fmpz, y::fmpz)
    iszero(y) && throw(DivideError())
    z1 = fmpz()
    z2 = fmpz()
    ccall((:fmpz_fdiv_qr, libflint), Nothing,
          (Ref{fmpz}, Ref{fmpz}, Ref{fmpz}, Ref{fmpz}), z1, z2, x, y)
    z1, z2
end

# N.B. Base.divrem differs from Nemo.divrem
function Base.divrem(x::fmpz, y::fmpz)
    iszero(y) && throw(DivideError())
    z1 = fmpz()
    z2 = fmpz()
    ccall((:fmpz_tdiv_qr, libflint), Nothing,
          (Ref{fmpz}, Ref{fmpz}, Ref{fmpz}, Ref{fmpz}), z1, z2, x, y)
    z1, z2
end

function tdivrem(x::fmpz, y::fmpz)
    iszero(y) && throw(DivideError())
    z1 = fmpz()
    z2 = fmpz()
    ccall((:fmpz_tdiv_qr, libflint), Nothing,
          (Ref{fmpz}, Ref{fmpz}, Ref{fmpz}, Ref{fmpz}), z1, z2, x, y)
    z1, z2
end

function fdivrem(x::fmpz, y::fmpz)
    iszero(y) && throw(DivideError())
    z1 = fmpz()
    z2 = fmpz()
    ccall((:fmpz_fdiv_qr, libflint), Nothing,
          (Ref{fmpz}, Ref{fmpz}, Ref{fmpz}, Ref{fmpz}), z1, z2, x, y)
    z1, z2
end

function cdivrem(x::fmpz, y::fmpz)
    iszero(y) && throw(DivideError())
    z1 = fmpz()
    z2 = fmpz()
    ccall((:fmpz_cdiv_qr, libflint), Nothing,
          (Ref{fmpz}, Ref{fmpz}, Ref{fmpz}, Ref{fmpz}), z1, z2, x, y)
    z1, z2
end

function ntdivrem(x::fmpz, y::fmpz)
    iszero(y) && throw(DivideError())
    z1 = fmpz()
    z2 = fmpz()
    ccall((:fmpz_ndiv_qr, libflint), Nothing,
          (Ref{fmpz}, Ref{fmpz}, Ref{fmpz}, Ref{fmpz}), z1, z2, x, y)
    return z1, z2
end

function nfdivrem(a::fmpz, b::fmpz)
   q, r = tdivrem(a, b)
   c = ccall((:fmpz_cmp2abs, libflint), Cint, (Ref{fmpz}, Ref{fmpz}), b, r)
   if c <= 0
      if ccall((:fmpz_sgn, libflint), Cint, (Ref{fmpz},), b) !=
         ccall((:fmpz_sgn, libflint), Cint, (Ref{fmpz},), r)
         sub!(q, q, UInt(1))
         add!(r, r, b)
      elseif c < 0
         add!(q, q, UInt(1))
         sub!(r, r, b)
      end
   end
   return (q, r)
end

function ncdivrem(a::fmpz, b::fmpz)
   q, r = tdivrem(a, b)
   c = ccall((:fmpz_cmp2abs, libflint), Cint, (Ref{fmpz}, Ref{fmpz}), b, r)
   if c <= 0
      if ccall((:fmpz_sgn, libflint), Cint, (Ref{fmpz},), r) ==
         ccall((:fmpz_sgn, libflint), Cint, (Ref{fmpz},), b)
         add!(q, q, UInt(1))
         sub!(r, r, b)
      elseif c < 0
         sub!(q, q, UInt(1))
         add!(r, r, b)
      end
   end
   return (q, r)
end

function ndivrem(x::fmpz, y::fmpz)
    iszero(y) && throw(DivideError())
    z1 = fmpz()
    z2 = fmpz()
    ccall((:fmpz_ndiv_qr, libflint), Nothing,
          (Ref{fmpz}, Ref{fmpz}, Ref{fmpz}, Ref{fmpz}), z1, z2, x, y)
    z1, z2
end

###############################################################################
#
#   Inversion
#
###############################################################################

function inv(x::fmpz)
   if isone(x)
      return fmpz(1)
   elseif x == -1
      return fmpz(-1)
   end
   iszero(x) && throw(DivideError())
   throw(ArgumentError("not a unit"))
end

###############################################################################
#
#   Powering
#
###############################################################################

function ^(x::fmpz, y::Union{Int, UInt, fmpz})
   if isone(x) || iszero(y)
      one(x)
   elseif x == -1
      isodd(y) ? deepcopy(x) : one(x)
   elseif y < 0
      throw(DomainError(y, "Exponent must be non-negative"))
   elseif isone(y)
      deepcopy(x)
   else
      z = fmpz()
      ccall((:fmpz_pow_ui, libflint), Nothing,
            (Ref{fmpz}, Ref{fmpz}, UInt), z, x, UInt(y))
      z
   end
end

###############################################################################
#
#   Comparison
#
###############################################################################

function cmp(x::fmpz, y::fmpz)
    Int(ccall((:fmpz_cmp, libflint), Cint,
              (Ref{fmpz}, Ref{fmpz}), x, y))
end

==(x::fmpz, y::fmpz) = cmp(x,y) == 0

<=(x::fmpz, y::fmpz) = cmp(x,y) <= 0

>=(x::fmpz, y::fmpz) = cmp(x,y) >= 0

<(x::fmpz, y::fmpz) = cmp(x,y) < 0

>(x::fmpz, y::fmpz) = cmp(x,y) > 0

function cmpabs(x::fmpz, y::fmpz)
    Int(ccall((:fmpz_cmpabs, libflint), Cint,
              (Ref{fmpz}, Ref{fmpz}), x, y))
end

isless(x::fmpz, y::fmpz) = x < y

isless(x::fmpz, y::Integer) = x < fmpz(y)

isless(x::Integer, y::fmpz) = fmpz(x) < y

###############################################################################
#
#   Ad hoc comparison
#
###############################################################################

function cmp(x::fmpz, y::Int)
    Int(ccall((:fmpz_cmp_si, libflint), Cint, (Ref{fmpz}, Int), x, y))
end

==(x::fmpz, y::Int) = cmp(x,y) == 0

<=(x::fmpz, y::Int) = cmp(x,y) <= 0

>=(x::fmpz, y::Int) = cmp(x,y) >= 0

<(x::fmpz, y::Int) = cmp(x,y) < 0

>(x::fmpz, y::Int) = cmp(x,y) > 0

==(x::Int, y::fmpz) = cmp(y,x) == 0

<=(x::Int, y::fmpz) = cmp(y,x) >= 0

>=(x::Int, y::fmpz) = cmp(y,x) <= 0

<(x::Int, y::fmpz) = cmp(y,x) > 0

>(x::Int, y::fmpz) = cmp(y,x) < 0

function cmp(x::fmpz, y::UInt)
    Int(ccall((:fmpz_cmp_ui, libflint), Cint, (Ref{fmpz}, UInt), x, y))
end

==(x::fmpz, y::UInt) = cmp(x,y) == 0

<=(x::fmpz, y::UInt) = cmp(x,y) <= 0

>=(x::fmpz, y::UInt) = cmp(x,y) >= 0

<(x::fmpz, y::UInt) = cmp(x,y) < 0

>(x::fmpz, y::UInt) = cmp(x,y) > 0

==(x::UInt, y::fmpz) = cmp(y,x) == 0

<=(x::UInt, y::fmpz) = cmp(y,x) >= 0

>=(x::UInt, y::fmpz) = cmp(y,x) <= 0

<(x::UInt, y::fmpz) = cmp(y,x) > 0

>(x::UInt, y::fmpz) = cmp(y,x) < 0

###############################################################################
#
#   Shifting
#
###############################################################################

@doc Markdown.doc"""
    <<(x::fmpz, c::Int)

Return $2^cx$ where $c \geq 0$.
"""
function <<(x::fmpz, c::Int)
    c < 0 && throw(DomainError(c, "Exponent must be non-negative"))
    c == 0 && return x
    z = fmpz()
    ccall((:fmpz_mul_2exp, libflint), Nothing,
          (Ref{fmpz}, Ref{fmpz}, Int), z, x, c)
    return z
end

@doc Markdown.doc"""
    >>(x::fmpz, c::Int)

Return $x/2^c$, discarding any remainder, where $c \geq 0$.
"""
function >>(x::fmpz, c::Int)
    c < 0 && throw(DomainError(c, "Exponent must be non-negative"))
    c == 0 && return x
    z = fmpz()
    ccall((:fmpz_fdiv_q_2exp, libflint), Nothing,
          (Ref{fmpz}, Ref{fmpz}, Int), z, x, c)
    return z
end

###############################################################################
#
#   Modular arithmetic
#
###############################################################################

function mod(x::fmpz, y::fmpz)
   iszero(y) && throw(DivideError())
   r = fmpz()
   ccall((:fmpz_fdiv_r, libflint), Nothing,
         (Ref{fmpz}, Ref{fmpz}, Ref{fmpz}), r, x, y)
   return r
end

function mod(x::fmpz, c::UInt)
    c == 0 && throw(DivideError())
    ccall((:fmpz_fdiv_ui, libflint), Base.GMP.Limb, (Ref{fmpz}, Base.GMP.Limb), x, c)
end

@doc Markdown.doc"""
    powermod(x::fmpz, p::fmpz, m::fmpz)

Return $x^p (\mod m)$. The remainder will be in the range $[0, m)$
"""
function powermod(x::fmpz, p::fmpz, m::fmpz)
    m <= 0 && throw(DomainError(m, "Exponent must be non-negative"))
    if p < 0
       x = invmod(x, m)
       p = -p
    end
    r = fmpz()
    ccall((:fmpz_powm, libflint), Nothing,
          (Ref{fmpz}, Ref{fmpz}, Ref{fmpz}, Ref{fmpz}),
          r, x, p, m)
    return r
end

@doc Markdown.doc"""
    powermod(x::fmpz, p::Int, m::fmpz)

Return $x^p (\mod m)$. The remainder will be in the range $[0, m)$
"""
function powermod(x::fmpz, p::Int, m::fmpz)
    m <= 0 && throw(DomainError(m, "Exponent must be non-negative"))
    if p < 0
       x = invmod(x, m)
       p = -p
    end
    r = fmpz()
    ccall((:fmpz_powm_ui, libflint), Nothing,
          (Ref{fmpz}, Ref{fmpz}, Int, Ref{fmpz}),
          r, x, p, m)
    return r
end

@doc Markdown.doc"""
    invmod(x::fmpz, m::fmpz)

Return $x^{-1} (\mod m)$. The remainder will be in the range $[0, m)$
"""
function invmod(x::fmpz, m::fmpz)
    m <= 0 && throw(DomainError(m, "Modulus must be non-negative"))
    z = fmpz()
    if isone(m)
        return fmpz(0)
    end
    if ccall((:fmpz_invmod, libflint), Cint,
             (Ref{fmpz}, Ref{fmpz}, Ref{fmpz}), z, x, m) == 0
       error("Impossible inverse in invmod")
    end
    return z
end

@doc Markdown.doc"""
    sqrtmod(x::fmpz, m::fmpz)

Return a square root of $x (\mod m)$ if one exists. The remainder will be in
the range $[0, m)$. We require that $m$ is prime, otherwise the algorithm may
not terminate.
"""
function sqrtmod(x::fmpz, m::fmpz)
    m <= 0 && throw(DomainError(m, "Modulus must be non-negative"))
    z = fmpz()
    if (ccall((:fmpz_sqrtmod, libflint), Cint,
              (Ref{fmpz}, Ref{fmpz}, Ref{fmpz}), z, x, m) == 0)
        error("no square root exists")
    end
    return z
end

@doc Markdown.doc"""
    crt(r1::fmpz, m1::fmpz, r2::fmpz, m2::fmpz, signed=false)

Return $r$ such that $r \equiv r_1 (\mod m_1)$ and $r \equiv r_2 (\mod m_2)$.
If `signed = true`, $r$ will be in the range $-m_1m_2/2 < r \leq m_1m_2/2$.
If `signed = false` the value will be in the range $0 \leq r < m_1m_2$.
"""
function crt(r1::fmpz, m1::fmpz, r2::fmpz, m2::fmpz, signed=false)
   z = fmpz()
   ccall((:fmpz_CRT, libflint), Nothing,
          (Ref{fmpz}, Ref{fmpz}, Ref{fmpz}, Ref{fmpz}, Ref{fmpz}, Cint),
          z, r1, m1, r2, m2, signed)
   return z
end

@doc Markdown.doc"""
    crt(r1::fmpz, m1::fmpz, r2::Int, m2::Int, signed=false)

Return $r$ such that $r \equiv r_1 (\mod m_1)$ and $r \equiv r_2 (\mod m_2)$.
If `signed = true`, $r$ will be in the range $-m_1m_2/2 < r \leq m_1m_2/2$.
If `signed = false` the value will be in the range $0 \leq r < m_1m_2$.
"""
function crt(r1::fmpz, m1::fmpz, r2::Int, m2::Int, signed = false)
   z = fmpz()
   r2 < 0 && throw(DomainError(r2, "Second residue must be non-negative"))
   m2 < 0 && throw(DomainError(m2, "Second modulus must be non-negative"))
   ccall((:fmpz_CRT_ui, libflint), Nothing,
          (Ref{fmpz}, Ref{fmpz}, Ref{fmpz}, Int, Int, Cint),
          z, r1, m1, r2, m2, signed)
   return z
end

###############################################################################
#
#   Integer logarithm
#
###############################################################################

@doc Markdown.doc"""
    flog(x::fmpz, c::fmpz)

Return the floor of the logarithm of $x$ to base $c$.
"""
function flog(x::fmpz, c::fmpz)
    c <= 0 && throw(DomainError(c, "Base must be non-negative"))
    x <= 0 && throw(DomainError(x, "Argument must be non-negative"))
    return ccall((:fmpz_flog, libflint), Int,
                 (Ref{fmpz}, Ref{fmpz}), x, c)
end

@doc Markdown.doc"""
    clog(x::fmpz, c::fmpz)

Return the ceiling of the logarithm of $x$ to base $c$.
"""
function clog(x::fmpz, c::fmpz)
    c <= 0 && throw(DomainError(c, "Base must be non-negative"))
    x <= 0 && throw(DomainError(x, "Argument must be non-negative"))
    return ccall((:fmpz_clog, libflint), Int,
                 (Ref{fmpz}, Ref{fmpz}), x, c)
end

@doc Markdown.doc"""
    flog(x::fmpz, c::Int)

Return the floor of the logarithm of $x$ to base $c$.
"""
function flog(x::fmpz, c::Int)
    c <= 0 && throw(DomainError(c, "Base must be non-negative"))
    return ccall((:fmpz_flog_ui, libflint), Int,
                 (Ref{fmpz}, Int), x, c)
end

@doc Markdown.doc"""
    clog(x::fmpz, c::Int)

Return the ceiling of the logarithm of $x$ to base $c$.
"""
function clog(x::fmpz, c::Int)
    c <= 0 && throw(DomainError(c, "Base must be non-negative"))
    return ccall((:fmpz_clog_ui, libflint), Int,
                 (Ref{fmpz}, Int), x, c)
end

###############################################################################
#
#   GCD and LCM
#
###############################################################################

@doc Markdown.doc"""
    gcd(x::fmpz, y::fmpz, z::fmpz...)

Return the greatest common divisor of $(x, y, ...)$. The returned result will
always be nonnegative and will be zero iff all inputs are zero.
"""
function gcd(x::fmpz, y::fmpz, z::fmpz...)
   d = fmpz()
   ccall((:fmpz_gcd, libflint), Nothing,
         (Ref{fmpz}, Ref{fmpz}, Ref{fmpz}), d, x, y)
   length(z) == 0 && return d

   for ix in 1:length(z)
     ccall((:fmpz_gcd, libflint), Nothing,
           (Ref{fmpz}, Ref{fmpz}, Ref{fmpz}), d, d, z[ix])
   end
   return d
end

@doc Markdown.doc"""
    gcd(x::Vector{fmpz})

Return the greatest common divisor of the elements of $x$. The returned
result will always be nonnegative and will be zero iff all elements of $x$
are zero.
"""
function gcd(x::Vector{fmpz})
   if length(x) == 0
      error("Array must not be empty")
   elseif length(x) == 1
      return x[1]
   end

   z = fmpz()
   ccall((:fmpz_gcd, libflint), Nothing,
         (Ref{fmpz}, Ref{fmpz}, Ref{fmpz}), z, x[1], x[2])

   for i in 3:length(x)
      ccall((:fmpz_gcd, libflint), Nothing,
            (Ref{fmpz}, Ref{fmpz}, Ref{fmpz}), z, z, x[i])
      if isone(z)
         return z
      end
   end

   return z
end

@doc Markdown.doc"""
    lcm(x::fmpz, y::fmpz, z::fmpz...)

Return the least common multiple of $(x, y, ...)$. The returned result will
always be nonnegative and will be zero if any input is zero.
"""
function lcm(x::fmpz, y::fmpz, z::fmpz...)
   m = fmpz()
   ccall((:fmpz_lcm, libflint), Nothing,
         (Ref{fmpz}, Ref{fmpz}, Ref{fmpz}), m, x, y)
   length(z) == 0 && return m

   for ix in 1:length(z)
     ccall((:fmpz_lcm, libflint), Nothing,
           (Ref{fmpz}, Ref{fmpz}, Ref{fmpz}), m, m, z[ix])
   end
   return m
end

@doc Markdown.doc"""
    lcm(x::Vector{fmpz})

Return the least common multiple of the elements of $x$. The returned result
will always be nonnegative and will be zero iff the elements of $x$ are zero.
"""
function lcm(x::Vector{fmpz})
   if length(x) == 0
      error("Array must not be empty")
   elseif length(x) == 1
      return x[1]
   end

   z = fmpz()
   ccall((:fmpz_lcm, libflint), Nothing,
         (Ref{fmpz}, Ref{fmpz}, Ref{fmpz}), z, x[1], x[2])

   for i in 3:length(x)
      ccall((:fmpz_lcm, libflint), Nothing,
            (Ref{fmpz}, Ref{fmpz}, Ref{fmpz}), z, z, x[i])
   end

   return z
end

gcd(a::fmpz, b::Integer) = gcd(a, fmpz(b))

gcd(a::Integer, b::fmpz) = gcd(fmpz(a), b)

lcm(a::fmpz, b::Integer) = lcm(a, fmpz(b))

lcm(a::Integer, b::fmpz) = lcm(fmpz(a), b)

###############################################################################
#
#   Extended GCD
#
###############################################################################

@doc Markdown.doc"""
    gcdx(a::fmpz, b::fmpz)

Return a tuple $g, s, t$ such that $g$ is the greatest common divisor of $a$
and $b$ and integers $s$ and $t$ such that $g = as + bt$.
"""
function gcdx(a::fmpz, b::fmpz)
  # Just to conform with Julia's definition
  a == b == 0 && return zero(FlintZZ), one(FlintZZ), zero(FlintZZ)

  d = FlintZZ()
  x = FlintZZ()
  y = FlintZZ()
  ccall((:fmpz_xgcd_canonical_bezout, libflint), Nothing,
        (Ref{fmpz}, Ref{fmpz}, Ref{fmpz}, Ref{fmpz}, Ref{fmpz}), d, x, y, a, b)
  return d, x, y
end

@doc Markdown.doc"""
    gcdinv(a::fmpz, b::fmpz)

Return a tuple $g, s$ where $g$ is the greatest common divisor of $a$ and
$b$ and where $s$ is the inverse of $a$ modulo $b$ if $g = 1$. This function
can be used to detect impossible inverses, i.e. where $a$ and $b$ are not
coprime, and to yield the common factor of $a$ and $b$ if they are not
coprime. We require $b \geq a \geq 0$.
"""
function gcdinv(a::fmpz, b::fmpz)
   a < 0 && throw(DomainError(a, "First argument must be non-negative"))
   b < a && throw(DomainError((a, b), "First argument must be smaller than second argument"))
   g = fmpz()
   s = fmpz()
   ccall((:fmpz_gcdinv, libflint), Nothing,
        (Ref{fmpz}, Ref{fmpz}, Ref{fmpz}, Ref{fmpz}),
        g, s, a, b)
   return g, s
end

gcdx(a::fmpz, b::Integer) = gcdx(a, fmpz(b))

gcdx(a::Integer, b::fmpz) = gcdx(fmpz(a), b)

gcdinv(a::fmpz, b::Integer) = gcdinv(a, fmpz(b))

gcdinv(a::Integer, b::fmpz) = gcdinv(fmpz(a), b)

###############################################################################
#
#   Roots
#
###############################################################################

sqrt_moduli = [3, 5, 7, 8]
sqrt_residues = [[0, 1], [0, 1, 4], [0, 1, 2, 4], [0, 1, 4]]

@doc Markdown.doc"""
    isqrt(x::fmpz)

Return the floor of the square root of $x$.
"""
function isqrt(x::fmpz)
    x < 0 && throw(DomainError(x, "Argument must be non-negative"))
    z = fmpz()
    ccall((:fmpz_sqrt, libflint), Nothing, (Ref{fmpz}, Ref{fmpz}), z, x)
    return z
end

@doc Markdown.doc"""
    isqrtrem(x::fmpz)

Return a tuple $s, r$ consisting of the floor $s$ of the square root of $x$
and the remainder $r$, i.e. such that $x = s^2 + r$. We require $x \geq 0$.
"""
function isqrtrem(x::fmpz)
    x < 0 && throw(DomainError(x, "Argument must be non-negative"))
    s = fmpz()
    r = fmpz()
    ccall((:fmpz_sqrtrem, libflint), Nothing,
          (Ref{fmpz}, Ref{fmpz}, Ref{fmpz}), s, r, x)
    return s, r
end

function Base.sqrt(x::fmpz; check=true)
    x < 0 && throw(DomainError(x, "Argument must be non-negative"))
    if check
       for i = 1:length(sqrt_moduli)
          res = mod(x, sqrt_moduli[i])
          !(res in sqrt_residues[i]) && error("Not a square")
       end
       s = fmpz()
       r = fmpz()
       ccall((:fmpz_sqrtrem, libflint), Nothing,
          (Ref{fmpz}, Ref{fmpz}, Ref{fmpz}), s, r, x)
       !iszero(r) && error("Not a square")
    else
       s = fmpz()
       ccall((:fmpz_sqrt, libflint), Nothing, (Ref{fmpz}, Ref{fmpz}), s, x)
    end
    return s
end

issquare(x::fmpz) = Bool(ccall((:fmpz_is_square, libflint), Cint,
                               (Ref{fmpz},), x))

function issquare_with_sqrt(x::fmpz)
    x < 0 && throw(DomainError(x, "Argument must be non-negative"))
    for i = 1:length(sqrt_moduli)
       res = mod(x, sqrt_moduli[i])
       if !(res in sqrt_residues[i])
          return false, zero(fmpz)
       end
    end
    s = fmpz()
    r = fmpz()
    ccall((:fmpz_sqrtrem, libflint), Nothing,
          (Ref{fmpz}, Ref{fmpz}, Ref{fmpz}), s, r, x)
    if !iszero(r)
       return false, zero(fmpz)
    end
    return true, s
end

@doc Markdown.doc"""
    root(x::fmpz, n::Int; check::Bool=true)

Return the $n$-the root of $x$. We require $n > 0$ and that
$x \geq 0$ if $n$ is even. By default the function tests whether the input was
a perfect $n$-th power and if not raises an exception. If `check=false` this
check is omitted.
"""
function root(x::fmpz, n::Int; check::Bool=true)
   x < 0 && iseven(n) && throw(DomainError((x, n), "Argument `x` must be positive if exponent `n` is even"))
   n <= 0 && throw(DomainError(n, "Exponent must be positive"))
   z = fmpz()
   res = ccall((:fmpz_root, libflint), Bool,
         (Ref{fmpz}, Ref{fmpz}, Int), z, x, n)
#= Check disabled until flint-2.9 comes out
   check && !res && error("Not a perfect n-th power (n = $n)")
=#
   return z
end

@doc Markdown.doc"""
    iroot(x::fmpz, n::Int)

Return the integer truncation of the $n$-the root of $x$ (round towards zero).
We require $n > 0$ and that $x \geq 0$ if $n$ is even.
"""
function iroot(x::fmpz, n::Int)
   x < 0 && iseven(n) && throw(DomainError((x, n), "Argument `x` must be positive if exponent `n` is even"))
   n <= 0 && throw(DomainError(n, "Exponent must be positive"))
   z = fmpz()
   ccall((:fmpz_root, libflint), Bool,
         (Ref{fmpz}, Ref{fmpz}, Int), z, x, n)
   return z
end

###############################################################################
#
#   Factorization
#
###############################################################################

function _factor(a::fmpz)
   F = fmpz_factor()
   ccall((:fmpz_factor, libflint), Nothing, (Ref{fmpz_factor}, Ref{fmpz}), F, a)
   res = Dict{fmpz, Int}()
   for i in 1:F.num
     z = fmpz()
     ccall((:fmpz_factor_get_fmpz, libflint), Nothing,
           (Ref{fmpz}, Ref{fmpz_factor}, Int), z, F, i - 1)
     res[z] = unsafe_load(F.exp, i)
   end
   return res, canonical_unit(a)
end

function factor(a::T) where T <: Union{Int, UInt}
   if iszero(a)
      throw(ArgumentError("Argument is not non-zero"))
   end
   u = sign(a)
   a = u < 0 ? -a : a
   F = n_factor()
   ccall((:n_factor, libflint), Nothing, (Ref{n_factor}, UInt), F, a)
   res = Dict{T, Int}()
   for i in 1:F.num
     z = F.p[i]
     res[z] = F.exp[i]
   end
   return Fac(u, res)
end

################################################################################
#
#   ECM
#
################################################################################

function _ecm(a::fmpz, B1::UInt, B2::UInt, ncrv::UInt,
             rnd = _flint_rand_states[Threads.threadid()])
  f = fmpz()
  r = ccall((:fmpz_factor_ecm, libflint), Int32,
            (Ref{fmpz}, UInt, UInt, UInt, Ptr{Cvoid}, Ref{fmpz}),
            f, ncrv, B1, B2, rnd.ptr, a)
  return r, f
end

function _ecm(a::fmpz, B1::Int, B2::Int, ncrv::Int,
             rnd = _flint_rand_states[Threads.threadid()])
  return _ecm(a, UInt(B1), UInt(B2), UInt(ncrv), rnd)
end

function ecm(a::fmpz, max_digits::Int = div(ndigits(a), 2) + 1,
             rnd = _flint_rand_states[Threads.threadid()],
             B1 = _ecm_B1s[Threads.threadid()],
             nC = _ecm_nCs[Threads.threadid()])
  n = ndigits(a, 10)
  B1s = 15

  i = 1
  s = div(max_digits-15, 5) + 2
  s = max(i, s)
  while i <= s
    e, f = _ecm(a, B1[i]*1000, B1[i]*1000*100, nC[i], rnd)
    if e != 0
      return (e,f)
    end
    i += 1
    if i > length(B1)
      return (e, f)
    end
  end
  return (Int32(0), a)
end

################################################################################
#
#   Factor trial range
#
################################################################################

function _factor_trial_range(N::fmpz, start::Int = 0, np::Int = 10^5)
   F = fmpz_factor()
   ccall((:fmpz_factor_trial_range, libflint), Nothing,
         (Ref{Nemo.fmpz_factor}, Ref{fmpz}, UInt, UInt), F, N, start, np)
   res = Dict{fmpz, Int}()
   for i in 1:F.num
     z = fmpz()
     ccall((:fmpz_factor_get_fmpz, libflint), Nothing,
           (Ref{fmpz}, Ref{Nemo.fmpz_factor}, Int), z, F, i - 1)
     res[z] = unsafe_load(F.exp, i)
   end
   return res, canonical_unit(N)
end

@doc Markdown.doc"""
    factor(a::fmpz)
    factor(a::UInt)
    factor(a::Int)

Return a factorisation of $a$ using a `Fac` struct (see the documentation on
factorisation in Nemo).
"""
function factor(a::fmpz)
   if iszero(a)
      throw(ArgumentError("Argument is not non-zero"))
   end
   fac, z = _factor(a)
   return Fac(z, fac)
end

###############################################################################
#
#   Number theoretic/combinatorial
#
###############################################################################

@doc Markdown.doc"""
    divisible(x::fmpz, y::fmpz)

Return `true` if $x$ is divisible by $y$, otherwise return `false`. We
require $x \neq 0$.
"""
function divisible(x::fmpz, y::fmpz)
   iszero(y) && throw(DivideError())
   Bool(ccall((:fmpz_divisible, libflint), Cint,
              (Ref{fmpz}, Ref{fmpz}), x, y))
end

@doc Markdown.doc"""
    divisible(x::fmpz, y::Int)

Return `true` if $x$ is divisible by $y$, otherwise return `false`. We
require $x \neq 0$.
"""
function divisible(x::fmpz, y::Int)
   y == 0 && throw(DivideError())
   Bool(ccall((:fmpz_divisible_si, libflint), Cint,
              (Ref{fmpz}, Int), x, y))
end

@doc Markdown.doc"""
    divisors(a::Union{Int, fmpz})

Return the positive divisors of $a$ in an array, not necessarily in growing
order. We require $a \neq 0$.
"""
function divisors end

function divisors(a::fmpz)
   iszero(a) && throw(DomainError("Argument must be non-zero"))

   divs = fmpz[one(FlintZZ)]
   isone(a) && return divs

   for (p,e) in factor(a)
      ndivs = copy(divs)
      for i = 1:e
         map!(d -> p*d, ndivs, ndivs)
         append!(divs, ndivs)
      end
   end

   return divs
end

divisors(a::Int) = Int.(divisors(FlintZZ(a)))

@doc Markdown.doc"""
    prime_divisors(a::fmpz)

Return the prime divisors of $a$ in an array. We require $a \neq 0$.
"""
function prime_divisors(a::fmpz)
   iszero(a) && throw(DomainError("Argument must be non-zero"))
   fmpz[p for (p, e) in factor(a)]
end

@doc Markdown.doc"""
    prime_divisors(a::Int)

Return the prime divisors of $a$ in an array. We require $a \neq 0$.
"""
prime_divisors(a::Int) = Int.(prime_divisors(FlintZZ(a)))

isprime(x::UInt) = Bool(ccall((:n_is_prime, libflint), Cint, (UInt,), x))

@doc Markdown.doc"""
    isprime(x::fmpz)

Return `true` if $x$ is a prime number, otherwise return `false`.
"""
function isprime(x::fmpz)
  !isprobable_prime(x) && return false
  return Bool(ccall((:fmpz_is_prime, libflint), Cint, (Ref{fmpz},), x))
end

@doc Markdown.doc"""
    isprime(x::Int)

Return `true` if $x$ is a prime number, otherwise return `false`.
"""
function isprime(n::Int)
  if n < 0
    return false
  end
  return isprime(n % UInt)
end

@doc Markdown.doc"""
    isprobable_prime(x::fmpz)

Return `true` if $x$ is very probably a prime number, otherwise return
`false`. No counterexamples are known to this test, but it is conjectured
that infinitely many exist.
"""
isprobable_prime(x::fmpz) = Bool(ccall((:fmpz_is_probabprime, libflint), Cint,
                                      (Ref{fmpz},), x))

@doc Markdown.doc"""
    next_prime(x::fmpz, proved = true)

Return the smallest prime strictly greater than $x$.
If a second argument of `false` is specified, the return is only probably prime.
"""
function next_prime(x::fmpz, proved::Bool = true)
   z = fmpz()
   ccall((:fmpz_nextprime, libflint), Nothing,
         (Ref{fmpz}, Ref{fmpz}, Cint),
         z, x, proved)
   return z
end

function next_prime(x::UInt, proved::Bool = true)
   if (Base.GMP.BITS_PER_LIMB == 64 && x >= 0xffffffffffffffc5) ||
      (Base.GMP.BITS_PER_LIMB == 32 && x >= 0xfffffffb)
         error("No larger single-limb prime exists")
   end
   return ccall((:n_nextprime, libflint), UInt,
                (UInt, Cint),
                x, proved)
end

function next_prime(x::Int, proved::Bool = true)
   return x < 2 ? 2 : Int(next_prime(x % UInt, proved))
end

function remove(x::fmpz, y::fmpz)
   iszero(y) && throw(DivideError())
   y <= 1 && error("Factor <= 1")
   z = fmpz()
   num = ccall((:fmpz_remove, libflint), Int,
               (Ref{fmpz}, Ref{fmpz}, Ref{fmpz}), z, x, y)
   return num, z
end

remove(x::fmpz, y::Integer) = remove(x, fmpz(y))

remove(x::Integer, y::fmpz) = remove(fmpz(x), y)

function remove(a::UInt, b::UInt)
   b <= 1 && error("Factor <= 1")
   a == 0 && error("Not yet implemented")
   q = Ref(a)
   binv = ccall((:n_precompute_inverse, libflint), Float64, (UInt,), b)
   v = ccall((:n_remove2_precomp, libflint), Cint,
             (Ptr{UInt}, UInt, Float64),
             q, b, binv)
   return (Int(v), q[])
end

function remove(a::Int, b::Int)
   b <= 1 && error("Factor <= 1")
   v, q = remove(abs(a)%UInt, b%UInt)
   return (v, a < 0 ? -q%Int : q%Int)
end

function remove(a::BigInt, b::BigInt)
   b <= 1 && error("Factor <= 1")
   a == 0 && error("Not yet implemented")
   q = BigInt()
   v =  ccall((:__gmpz_remove, :libgmp), Culong,
              (Ref{BigInt}, Ref{BigInt}, Ref{BigInt}),
              q, a, b)
   return (Int(v), q)
end

function remove(x::Integer, y::Integer)
   v, q = remove(fmpz(x), fmpz(y))
   return (v, convert(promote_type(typeof(x), typeof(y)), q))
end

@doc Markdown.doc"""
    valuation(x::fmpz, y::fmpz)

Return the largest $n$ such that $y^n$ divides $x$.
"""
function valuation(x::fmpz, y::fmpz)
   iszero(x) && error("Not yet implemented")
   n, _ = remove(x, y)
   return n
end

valuation(x::fmpz, y::Integer) = valuation(x, fmpz(y))

valuation(x::Integer, y::fmpz) = valuation(fmpz(x), y)

valuation(x::Integer, y::Integer) = valuation(fmpz(x), fmpz(y))

@doc Markdown.doc"""
    divisor_lenstra(n::fmpz, r::fmpz, m::fmpz)

If $n$ has a factor which lies in the residue class $r (\mod m)$ for
$0 < r < m < n$, this function returns such a factor. Otherwise it returns
$0$. This is only efficient if $m$ is at least the cube root of $n$. We
require gcd$(r, m) = 1$ and this condition is not checked.
"""
function divisor_lenstra(n::fmpz, r::fmpz, m::fmpz)
   r <= 0 && throw(DomainError(r, "Residue class must be non-negative"))
   m <= r && throw(DomainError((m, r), "Modulus must be bigger than residue class"))
   n <= m && throw(DomainError((n, m), "Argument must be bigger than modulus"))
   z = fmpz()
   if !Bool(ccall((:fmpz_divisor_in_residue_class_lenstra, libflint),
       Cint, (Ref{fmpz}, Ref{fmpz}, Ref{fmpz}, Ref{fmpz}), z, n, r, m))
      z = 0
   end
   return z
end

@doc Markdown.doc"""
    factorial(x::fmpz)

Return the factorial of $x$, i.e. $x! = 1.2.3\ldots x$. We require
$x \geq 0$.
"""
function factorial(x::fmpz)
    x < 0 && throw(DomainError(x, "Argument must be non-negative"))
    z = fmpz()
    ccall((:fmpz_fac_ui, libflint), Nothing, (Ref{fmpz}, UInt), z, UInt(x))
    return z
end

@doc Markdown.doc"""
    rising_factorial(x::fmpz, n::Int)

Return the rising factorial of $x$, i.e. $x(x + 1)(x + 2)\ldots (x + n - 1)$.
If $n < 0$ we throw a `DomainError()`.
"""
function rising_factorial(x::fmpz, n::Int)
    n < 0 && throw(DomainError(n, "Argument must be non-negative"))
    z = fmpz()
    ccall((:fmpz_rfac_ui, libflint), Nothing,
          (Ref{fmpz}, Ref{fmpz}, UInt), z, x, UInt(n))
    return z
end

@doc Markdown.doc"""
    rising_factorial(x::fmpz, n::fmpz)

Return the rising factorial of $x$, i.e. $x(x + 1)(x + 2)\cdots (x + n - 1)$.
If $n < 0$ we throw a `DomainError()`.
"""
rising_factorial(x::fmpz, n::fmpz) = rising_factorial(x, Int(n))

@doc Markdown.doc"""
    rising_factorial(x::Int, n::Int)

Return the rising factorial of $x$, i.e. $x(x + 1)(x + 2)\ldots (x + n - 1)$.
If $n < 0$ we throw a `DomainError()`.
"""
function rising_factorial(x::Int, n::Int)
    n < 0 && throw(DomainError(n, "Argument must be non-negative"))
    z = fmpz()
    if x < 0
       if n <= -x # we don't pass zero
          z = isodd(n) ? -rising_factorial(-x - n + 1, n) :
                          rising_factorial(-x - n + 1, n)
       end
    else
       ccall((:fmpz_rfac_uiui, libflint), Nothing,
             (Ref{fmpz}, UInt, UInt), z, x, n)
    end
    return Int(z)
end

@doc Markdown.doc"""
    primorial(x::Int)

Return the primorial of $x$, i.e. the product of all primes less than or
equal to $x$. If $x < 0$ we throw a `DomainError()`.
"""
function primorial(x::Int)
    x < 0 && throw(DomainError(x, "Argument must be non-negative"))
    z = fmpz()
    ccall((:fmpz_primorial, libflint), Nothing,
          (Ref{fmpz}, UInt), z, UInt(x))
    return Int(z)
end

@doc Markdown.doc"""
    primorial(x::fmpz)

Return the primorial of $x$, i.e. the product of all primes less than or
equal to $x$. If $x < 0$ we throw a `DomainError()`.
"""
function primorial(x::fmpz)
    x < 0 && throw(DomainError(x, "Argument must be non-negative"))
    z = fmpz()
    ccall((:fmpz_primorial, libflint), Nothing,
          (Ref{fmpz}, UInt), z, UInt(x))
    return z
end

@doc Markdown.doc"""
    fibonacci(x::Int)

Return the $x$-th Fibonacci number $F_x$. We define $F_1 = 1$, $F_2 = 1$ and
$F_{i + 1} = F_i + F_{i - 1}$ for all integers $i$.
"""
function fibonacci(x::Int)
    z = fmpz()
    ccall((:fmpz_fib_ui, libflint), Nothing,
          (Ref{fmpz}, UInt), z, UInt(abs(x)))
    return x < 0 ? (iseven(x) ? -Int(z) : Int(z)) : Int(z)
end

@doc Markdown.doc"""
    fibonacci(x::fmpz)

Return the $x$-th Fibonacci number $F_x$. We define $F_1 = 1$, $F_2 = 1$ and
$F_{i + 1} = F_i + F_{i - 1}$ for all integers $i$.
"""
function fibonacci(x::fmpz)
    z = fmpz()
    ccall((:fmpz_fib_ui, libflint), Nothing,
          (Ref{fmpz}, UInt), z, UInt(abs(x)))
    return x < 0 ? (iseven(x) ? -z : z) : z
end

@doc Markdown.doc"""
    bell(x::Int)

Return the Bell number $B_x$.
"""
function bell(x::Int)
    x < 0 && throw(DomainError(x, "Argument must be non-negative"))
    z = fmpz()
    ccall((:arith_bell_number, libflint), Nothing,
          (Ref{fmpz}, UInt), z, UInt(x))
    return Int(z)
end

@doc Markdown.doc"""
    bell(x::fmpz)

Return the Bell number $B_x$.
"""
function bell(x::fmpz)
    x < 0 && throw(DomainError(x, "Argument must be non-negative"))
    z = fmpz()
    ccall((:arith_bell_number, libflint), Nothing,
          (Ref{fmpz}, UInt), z, UInt(x))
    return z
end

@doc Markdown.doc"""
    binomial(n::fmpz, k::fmpz)

Return the binomial coefficient $\frac{n!}{(n - k)!k!}$. If $n, k < 0$ or
$k > n$ we return $0$.
"""
function binomial(n::fmpz, k::fmpz)
    n < 0 && return fmpz(0)
    k < 0 && return fmpz(0)
    z = fmpz()
    ccall((:fmpz_bin_uiui, libflint), Nothing,
          (Ref{fmpz}, UInt, UInt), z, UInt(n), UInt(k))
    return z
end

@doc Markdown.doc"""
    moebius_mu(x::fmpz)

Return the Moebius mu function of $x$ as an `Int`. The value
returned is either $-1$, $0$ or $1$. If $x \leq 0$ we throw a `DomainError()`.
"""
function moebius_mu(x::fmpz)
   x <= 0 && throw(DomainError(x, "Argument must be positive"))
   return Int(ccall((:fmpz_moebius_mu, libflint), Cint,
                    (Ref{fmpz},), x))
end

@doc Markdown.doc"""
    moebius_mu(x::Int)

Return the Moebius mu function of $x$ as an `Int`. The value
returned is either $-1$, $0$ or $1$. If $x \leq 0$ we throw a `DomainError()`.
"""
moebius_mu(x::Int) = moebius_mu(fmpz(x))

@doc Markdown.doc"""
    jacobi_symbol(x::fmpz, y::fmpz)

Return the value of the Jacobi symbol $\left(\frac{x}{y}\right)$. The modulus
$y$ must be odd and positive, otherwise a `DomainError` is thrown.
"""
function jacobi_symbol(x::fmpz, y::fmpz)
   (y <= 0 || iseven(y)) && throw(DomainError(y, "Modulus must be odd and positive"))
   if x < 0 || x >= y
      x = mod(x, y)
   end
   return Int(ccall((:fmpz_jacobi, libflint), Cint,
                    (Ref{fmpz}, Ref{fmpz}), x, y))
end

@doc Markdown.doc"""
    jacobi_symbol(x::Int, y::Int)

Return the value of the Jacobi symbol $\left(\frac{x}{y}\right)$. The modulus
$y$ must be odd and positive, otherwise a `DomainError` is thrown.
"""
function jacobi_symbol(x::Int, y::Int)
   (y <= 0 || mod(y, 2) == 0) && throw(DomainError(y, "Modulus must be odd and positive"))
   if x < 0 || x >= y
      x = mod(x, y)
   end
   return Int(ccall((:n_jacobi, libflint), Cint, (Int, UInt), x, UInt(y)))
end

@doc Markdown.doc"""
    kronecker_symbol(x::fmpz, y::fmpz)
    kronecker_symbol(x::Int, y::Int)

Return the value of the Kronecker symbol $\left(\frac{x}{y}\right)$.
The definition is as per Henri Cohen's book, "A Course in Computational
Algebraic Number Theory", Definition 1.4.8.
"""
function kronecker_symbol(x::Int, y::Int)
   return Int(ccall((:z_kronecker, libflint), Cint,
                    (Int, Int), x, y))
end

function kronecker_symbol(x::fmpz, y::fmpz)
   return Int(ccall((:fmpz_kronecker, libflint), Cint,
                    (Ref{fmpz}, Ref{fmpz}), x, y))
end

@doc Markdown.doc"""
    divisor_sigma(x::fmpz, y::Int)

Return the value of the sigma function, i.e. $\sum_{0 < d \;| x} d^y$. If
$x \leq 0$ or $y < 0$ we throw a `DomainError()`.
"""
function divisor_sigma(x::fmpz, y::Int)
   x <= 0 && throw(DomainError(x, "Argument must be positive"))
   y < 0 && throw(DomainError(y, "Power must be non-negative"))
   z = fmpz()
   ccall((:fmpz_divisor_sigma, libflint), Nothing,
         (Ref{fmpz}, Ref{fmpz}, Int), z, x, y)
   return z
end

@doc Markdown.doc"""
    divisor_sigma(x::fmpz, y::fmpz)

Return the value of the sigma function, i.e. $\sum_{0 < d \;| x} d^y$. If
$x \leq 0$ or $y < 0$ we throw a `DomainError()`.
"""
divisor_sigma(x::fmpz, y::fmpz) = divisor_sigma(x, Int(y))

@doc Markdown.doc"""
    divisor_sigma(x::Int, y::Int)

Return the value of the sigma function, i.e. $\sum_{0 < d \;| x} d^y$. If
$x \leq 0$ or $y < 0$ we throw a `DomainError()`.
"""
divisor_sigma(x::Int, y::Int) = Int(divisor_sigma(fmpz(x), y))

@doc Markdown.doc"""
    euler_phi(x::fmpz)

Return the value of the Euler phi function at $x$, i.e. the number of
positive integers up to $x$ (inclusive) that are coprime with $x$. An
exception is raised if $x \leq 0$.
"""
function euler_phi(x::fmpz)
   x <= 0 && throw(DomainError(x, "Argument must be positive"))
   z = fmpz()
   ccall((:fmpz_euler_phi, libflint), Nothing,
         (Ref{fmpz}, Ref{fmpz}), z, x)
   return z
end

@doc Markdown.doc"""
    euler_phi(x::Int)

Return the value of the Euler phi function at $x$, i.e. the number of
positive integers up to $x$ (inclusive) that are coprime with $x$. An
exception is raised if $x \leq 0$.
"""
euler_phi(x::Int) = Int(euler_phi(fmpz(x)))

@doc Markdown.doc"""
    number_of_partitions(x::Int)

Return the number of partitions of $x$. This function is not available on
Windows 64.
"""
function number_of_partitions(x::Int)
   if (Sys.iswindows() ? true : false) && Int == Int64
      error("not yet supported on win64")
   end
   z = fmpz()
   if x < 0
      return 0
   end
   ccall((:partitions_fmpz_ui, libarb), Nothing,
         (Ref{fmpz}, UInt), z, x)
   return Int(z)
end

@doc Markdown.doc"""
    number_of_partitions(x::fmpz)

Return the number of partitions of $x$. This function is not available on
Windows 64.
"""
function number_of_partitions(x::fmpz)
   if (Sys.iswindows() ? true : false) && Int == Int64
      error("not yet supported on win64")
   end
   z = fmpz()
   if x < 0
      return z
   end
   ccall((:partitions_fmpz_fmpz, libarb), Nothing,
         (Ref{fmpz}, Ref{fmpz}, Int), z, x, 0)
   return z
end

###############################################################################
#
#   Number bases/digits
#
###############################################################################

@doc Markdown.doc"""
    bin(n::fmpz)

Return $n$ as a binary string.
"""
bin(n::fmpz) = base(n, 2)

@doc Markdown.doc"""
    oct(n::fmpz)

Return $n$ as a octal string.
"""
oct(n::fmpz) = base(n, 8)

@doc Markdown.doc"""
    dec(n::fmpz)

Return $n$ as a decimal string.
"""
dec(n::fmpz) = base(n, 10)

@doc Markdown.doc"""
    hex(n::fmpz) = base(n, 16)

Return $n$ as a hexadecimal string.
"""
hex(n::fmpz) = base(n, 16)

@doc Markdown.doc"""
    base(n::fmpz, b::Integer)

Return $n$ as a string in base $b$. We require $2 \leq b \leq 62$.
"""
function base(n::fmpz, b::Integer)
    2 <= b <= 62 || error("invalid base: $b")
    p = ccall((:fmpz_get_str,libflint), Ptr{UInt8},
              (Ptr{UInt8}, Cint, Ref{fmpz}), C_NULL, b, n)
    s = unsafe_string(p)
    ccall((:flint_free, libflint), Nothing, (Ptr{UInt8},), p)
    return s
end

@doc Markdown.doc"""
    ndigits(x::fmpz, b::Integer)

Return the number of digits of $x$ in the base $b$ (default is $b = 10$).
"""
function ndigits(x::fmpz, b::Integer)::Int
   ndigits(x, base=b)
end

function Base.ndigits(a::fmpz; base::Integer = 10, pad::Integer = 1)
   iszero(a) && return 1
   return max(pad, 1+flog(abs(a), fmpz(abs(base))))
end

Base.digits(n::fmpz; base::Integer = 10, pad::Integer = 1) =
   digits(typeof(base), n, base = base, pad = pad)

function Base.digits(T::Type{<:Integer}, n::fmpz; base::Integer = 10, pad::Integer = 1)
   digits!(zeros(T, ndigits(n, base=base, pad=pad)), n, base=base)
end

function Base.digits!(a::AbstractVector{T}, n::fmpz; base::Integer = 10) where T<:Integer
   2 <= base || throw(DomainError(base, "base must be ≥ 2"))
   Base.hastypemax(T) && abs(base) - 1 > typemax(T) &&
       throw(ArgumentError("type $T too small for base $base"))
   isempty(a) && return a

   if nbits(n)/ndigits(base, base = 2) > 100
     c = div(div(nbits(n), ndigits(base, base = 2)), 2)
     nn = fmpz(base)^c
     q, r = divrem(n, nn)

     digits!(view(a, 1:c), r, base = base)
     digits!(view(a, c+1:length(a)), q, base = base)
     return a
   end

   for i in eachindex(a)
      n, r = divrem(n, base)
      a[i] = r
   end
   return a
end

@doc Markdown.doc"""
    nbits(x::fmpz)

Return the number of binary bits of $x$. We return zero if $x = 0$.
"""
nbits(x::fmpz) = iszero(x) ? 0 : Int(ccall((:fmpz_sizeinbase, libflint), UInt,
                  (Ref{fmpz}, Int32), x, 2))  # docu states: always correct
                                #if base is power of 2

###############################################################################
#
#   Bit fiddling
#
###############################################################################

@doc Markdown.doc"""
    popcount(x::fmpz)

Return the number of ones in the binary representation of $x$.
"""
popcount(x::fmpz) = Int(ccall((:fmpz_popcnt, libflint), UInt,
                              (Ref{fmpz},), x))

@doc Markdown.doc"""
    prevpow2(x::fmpz)

Return the previous power of $2$ up to including $x$.
"""
prevpow2(x::fmpz) = x < 0 ? -prevpow2(-x) :
                            (x <= 2 ? x : one(FlintZZ) << (ndigits(x, 2) - 1))

@doc Markdown.doc"""
    nextpow2(x::fmpz)

Return the next power of $2$ that is at least $x$.
"""
nextpow2(x::fmpz) = x < 0 ? -nextpow2(-x) :
                            (x <= 2 ? x : one(FlintZZ) << ndigits(x - 1, 2))

@doc Markdown.doc"""
    trailing_zeros(x::fmpz)

Return the number of trailing zeros in the binary representation of $x$.
"""
trailing_zeros(x::fmpz) = ccall((:fmpz_val2, libflint), Int,
                                (Ref{fmpz},), x)

###############################################################################
#
#   Bitwise operations (unsafe)
#
###############################################################################

@doc Markdown.doc"""
    clrbit!(x::fmpz, c::Int)

Clear bit $c$ of $x$, where the least significant bit is the $0$-th bit. Note
that this function modifies its input in-place.
"""
function clrbit!(x::fmpz, c::Int)
    c < 0 && throw(DomainError(c, "Second argument must be non-negative"))
    ccall((:fmpz_clrbit, libflint), Nothing, (Ref{fmpz}, UInt), x, c)
end

@doc Markdown.doc"""
    setbit!(x::fmpz, c::Int)

Set bit $c$ of $x$, where the least significant bit is the $0$-th bit. Note
that this function modifies its input in-place.
"""
function setbit!(x::fmpz, c::Int)
    c < 0 && throw(DomainError(c, "Second argument must be non-negative"))
    ccall((:fmpz_setbit, libflint), Nothing, (Ref{fmpz}, UInt), x, c)
end

@doc Markdown.doc"""
    combit!(x::fmpz, c::Int)

Complement bit $c$ of $x$, where the least significant bit is the $0$-th bit.
Note that this function modifies its input in-place.
"""
function combit!(x::fmpz, c::Int)
    c < 0 && throw(DomainError(c, "Second argument must be non-negative"))
    ccall((:fmpz_combit, libflint), Nothing, (Ref{fmpz}, UInt), x, c)
end

@doc Markdown.doc"""
    tstbit(x::fmpz, c::Int)

Return bit $i$ of x (numbered from 0) as `true` for 1 or `false` for 0.
"""
function tstbit(x::fmpz, c::Int)
   return c >= 0 && Bool(ccall((:fmpz_tstbit, libflint), Cint,
                               (Ref{fmpz}, UInt),
                               x, c))
end

###############################################################################
#
#   Unsafe operators
#
###############################################################################

function zero!(z::fmpz)
   ccall((:fmpz_zero, libflint), Nothing,
         (Ref{fmpz},), z)
   return z
end

function one!(z::fmpz)
   ccall((:fmpz_set_ui, libflint), Nothing,
         (Ref{fmpz}, UInt),
         z, 1)
   return z
end

function set!(z::fmpz, a::fmpz)
   ccall((:fmpz_set, libflint), Nothing,
         (Ref{fmpz}, Ref{fmpz}),
         z, a)
   return z
end

function swap!(a::fmpz, b::fmpz)
   ccall((:fmpz_swap, libflint), Nothing,
         (Ref{fmpz}, Ref{fmpz}),
         a, b)
end

function addeq!(z::fmpz, x::fmpz)
   ccall((:fmpz_add, libflint), Nothing,
         (Ref{fmpz}, Ref{fmpz}, Ref{fmpz}), z, z, x)
   return z
end

function add!(z::fmpz, x::fmpz, y::fmpz)
   ccall((:fmpz_add, libflint), Nothing,
         (Ref{fmpz}, Ref{fmpz}, Ref{fmpz}), z, x, y)
   return z
end

function add!(z::fmpz, x::fmpz, y::Int)
   ccall((:fmpz_add_si, libflint), Nothing,
         (Ref{fmpz}, Ref{fmpz}, Int), z, x, y)
   return z
end

function add!(z::fmpz, a::fmpz, b::UInt)
   ccall((:fmpz_add_ui, libflint), Nothing,
         (Ref{fmpz}, Ref{fmpz}, UInt),
         z, a, b)
   return z
end

add!(z::fmpz, a::fmpz, b::Integer) = add!(z, a, fmpz(b))
add!(z::fmpz, x::Int, y::fmpz) = add!(z, y, x)

function neg!(z::fmpz, a::fmpz)
   ccall((:fmpz_neg, libflint), Nothing,
         (Ref{fmpz}, Ref{fmpz}),
         z, a)
   return z
end

function sub!(z::fmpz, a::fmpz, b::fmpz)
   ccall((:fmpz_sub, libflint), Nothing,
         (Ref{fmpz}, Ref{fmpz}, Ref{fmpz}),
         z, a, b)
   return z
end

function sub!(z::fmpz, a::fmpz, b::Int)
   ccall((:fmpz_sub_si, libflint), Nothing,
         (Ref{fmpz}, Ref{fmpz}, Int),
         z, a, b)
   return z
end

function sub!(z::fmpz, a::fmpz, b::UInt)
   ccall((:fmpz_sub_ui, libflint), Nothing,
         (Ref{fmpz}, Ref{fmpz}, UInt),
         z, a, b)
   return z
end

function sub!(z::fmpz, a::fmpz, b::Integer)
   return sub!(z, a, fmpz(b))
end

function sub!(z::fmpz, b::Integer, a::fmpz)
   sub!(z, a, b)
   return neg!(z, z)
end


function mul!(z::fmpz, x::fmpz, y::fmpz)
   ccall((:fmpz_mul, libflint), Nothing,
         (Ref{fmpz}, Ref{fmpz}, Ref{fmpz}), z, x, y)
   return z
end

function mul!(z::fmpz, x::fmpz, y::Int)
   ccall((:fmpz_mul_si, libflint), Nothing,
         (Ref{fmpz}, Ref{fmpz}, Int), z, x, y)
   return z
end

function mul!(z::fmpz, a::fmpz, b::UInt)
   ccall((:fmpz_mul_ui, libflint), Nothing,
         (Ref{fmpz}, Ref{fmpz}, UInt),
         z, a, b)
   return z
end

mul!(z::fmpz, a::fmpz, b::Integer) = mul!(z, a, fmpz(b))

mul!(z::fmpz, x::Int, y::fmpz) = mul!(z, y, x)

function addmul!(z::fmpz, x::fmpz, y::fmpz)
   ccall((:fmpz_addmul, libflint), Nothing,
         (Ref{fmpz}, Ref{fmpz}, Ref{fmpz}), z, x, y)
   return z
end

addmul!(z::fmpz, x::fmpz, y::fmpz, ::fmpz) = addmul!(z, x, y)

function addmul!(z::fmpz, x::fmpz, y::Int)
   ccall((:fmpz_addmul_si, libflint), Nothing,
         (Ref{fmpz}, Ref{fmpz}, Int), z, x, y)
   return z
end

addmul!(z::fmpz, x::fmpz, y::Int, ::fmpz) = addmul!(z, x, y)

function submul!(z::fmpz, a::fmpz, b::fmpz)
   ccall((:fmpz_submul, libflint), Nothing,
         (Ref{fmpz}, Ref{fmpz}, Ref{fmpz}),
         z, a, b)
   return z
end

function divexact!(z::fmpz, a::fmpz, b::fmpz)
   ccall((:fmpz_divexact, libflint), Nothing,
         (Ref{fmpz}, Ref{fmpz}, Ref{fmpz}),
         z, a, b)
   return z
end

function pow!(z::fmpz, a::fmpz, b::Union{Int, UInt})
   ccall((:fmpz_pow_ui, libflint), Nothing,
         (Ref{fmpz}, Ref{fmpz}, UInt),
         z, a, UInt(b))
   return z
end

###############################################################################
#
#   Parent object overloads
#
###############################################################################

(::FlintIntegerRing)() = fmpz()

(::FlintIntegerRing)(a::Integer) = fmpz(a)

(::FlintIntegerRing)(a::AbstractString) = fmpz(a)

(::FlintIntegerRing)(a::fmpz) = a

(::FlintIntegerRing)(a::Float64) = fmpz(a)

(::FlintIntegerRing)(a::Float32) = fmpz(Float64(a))

(::FlintIntegerRing)(a::Float16) = fmpz(Float64(a))

(::FlintIntegerRing)(a::BigFloat) = fmpz(BigInt(a))

###############################################################################
#
#   String parser
#
###############################################################################

function parse(::Type{fmpz}, s::String, base::Int = 10)
    s = string(s)
    sgn = s[1] == '-' ? -1 : 1
    i = 1 + (sgn == -1)
    z = fmpz()
    err = ccall((:fmpz_set_str, libflint),
               Int32, (Ref{fmpz}, Ptr{UInt8}, Int32),
               z, string(SubString(s, i)), base)
    err == 0 || error("Invalid big integer: $(repr(s))")
    return sgn < 0 ? -z : z
end

###############################################################################
#
#   Random generation
#
###############################################################################

RandomExtensions.maketype(R::FlintIntegerRing, _) = fmpz

# define rand(make(ZZ, n:m))
rand(rng::AbstractRNG, sp::SamplerTrivial{<:Make2{fmpz,FlintIntegerRing}}) =
        sp[][1](rand(rng, sp[][2]))

rand(rng::AbstractRNG, R::FlintIntegerRing, n::AbstractArray) = R(rand(rng, n))

rand(R::FlintIntegerRing, n::AbstractArray) = rand(Random.GLOBAL_RNG, R, n)

@doc Markdown.doc"""
    rand_bits(::FlintIntegerRing, b::Int)

Return a random signed integer whose absolute value has $b$ bits.
"""
function rand_bits(::FlintIntegerRing, b::Int)
   b >= 0 || throw(DomainError(b, "Bit count must be non-negative"))
   z = fmpz()
   ccall((:fmpz_randbits, libflint), Nothing,(Ref{fmpz}, Ptr{Cvoid}, Int),
         z, _flint_rand_states[Threads.threadid()].ptr, b)
   return z
end

@doc Markdown.doc"""
    rand_bits_prime(::FlintIntegerRing, n::Int, proved::Bool=true)

Return a random prime number with the given number of bits. If only a
probable prime is required, one can pass `proved=false`.
"""
function rand_bits_prime(::FlintIntegerRing, n::Int, proved::Bool = true)
   n < 2 && throw(DomainError(n, "No primes with that many bits"))
   z = fmpz()
   ccall((:fmpz_randprime, libflint), Nothing,
	 (Ref{fmpz}, Ptr{Cvoid}, Int, Cint),
	  z, _flint_rand_states[Threads.threadid()].ptr, n, Cint(proved))
   return z
end

# rand in a range
# this mirrors the implementation for BigInt in the Random module

using Base.GMP: Limb, MPZ

# "views" a non-small fmpz as a readonly BigInt
# the caller must call GC.@preserve appropriately
function _as_bigint(z::fmpz)
   @assert !_fmpz_is_small(z)
   unsafe_load(Ptr{BigInt}(z.d << 2))
end


Random.Sampler(::Type{<:AbstractRNG}, r::StepRange{fmpz, fmpz}, ::Random.Repetition) =
   SamplerFmpz(r)

struct SamplerFmpz <: Random.Sampler{fmpz}
   a::fmpz           # first
   m::BigInt         # range length - 1
   nlimbs::Int       # number of limbs in generated BigInt's (z ∈ [0, m])
   nlimbsmax::Int    # max number of limbs for z+a
   mask::Limb        # applied to the highest limb

   ## diverges from Random.SamplerBigInt:
   step::fmpz
end

function SamplerFmpz(r::StepRange{fmpz, fmpz})
   r1 = first(r)
   r2 = last(r)
   s = step(r)

   if isone(s)
      m = BigInt(r2 - r1)
   else
      m = length(r)::BigInt # type assertion in case length is changed to return an fmpz
      MPZ.sub_ui!(m, 1)
   end

   m < 0 && throw(ArgumentError("range must be non-empty"))
   nd = ndigits(m, base=2)
   nlimbs, highbits = divrem(nd, 8*sizeof(Limb))
   highbits > 0 && (nlimbs += 1)
   mask = highbits == 0 ? ~zero(Limb) : one(Limb)<<highbits - one(Limb)
   GC.@preserve r1 r2 begin
      a1 = _fmpz_is_small(r1) ? 1 : _as_bigint(r1).size
      a2 = _fmpz_is_small(r2) ? 1 : _as_bigint(r2).size
   end
   nlimbsmax = max(nlimbs, abs(a1), abs(a2))
   return SamplerFmpz(r1, m, nlimbs, nlimbsmax, mask, s)
end

function rand(rng::AbstractRNG, sp::SamplerFmpz)
   z = fmpz()
   # this make sure z is backed up by an mpz_t object:
   ccall((:fmpz_init2, libflint), Nothing, (Ref{fmpz}, UInt), z, sp.nlimbsmax)
   @assert !_fmpz_is_small(z)
   GC.@preserve z begin
      x = _as_bigint(z)
      limbs = Random.UnsafeView(x.d, sp.nlimbs)
      while true
         rand!(rng, limbs)
         limbs[end] &= sp.mask
         MPZ.mpn_cmp(x, sp.m, sp.nlimbs) <= 0 && break
      end
      # adjust x.size (normally done by mpz_limbs_finish, in GMP version >= 6)
      sz = sp.nlimbs
      while sz > 0
         limbs[sz] != 0 && break
         sz -= 1
      end
      # write sz in the .size field of the mpz object
      unsafe_store!(Ptr{Cint}(z.d << 2) + sizeof(Cint), sz)
   end
   if !isone(sp.step)
      mul!(z, z, sp.step)
   end
   add!(z, z, sp.a)
end


###############################################################################
#
#   Constructors
#
###############################################################################

fmpz(s::AbstractString) = parse(fmpz, s)

fmpz(z::Integer) = fmpz(BigInt(z))

fmpz(z::Float16) = fmpz(Float64(z))

fmpz(z::Float32) = fmpz(Float64(z))

fmpz(z::BigFloat) = fmpz(BigInt(z))

###############################################################################
#
#   Conversions and promotions
#
###############################################################################

convert(::Type{fmpz}, a::Integer) = fmpz(a)

function (::Type{BigInt})(a::fmpz)
   r = BigInt()
   ccall((:fmpz_get_mpz, libflint), Nothing, (Ref{BigInt}, Ref{fmpz}), r, a)
   return r
end

convert(::Type{BigInt}, a::fmpz) = BigInt(a)

function (::Type{Int})(a::fmpz)
   (a > typemax(Int) || a < typemin(Int)) && throw(InexactError(:convert, Int, a))
   return ccall((:fmpz_get_si, libflint), Int, (Ref{fmpz},), a)
end

convert(::Type{Int}, a::fmpz) = Int(a)

function (::Type{UInt})(a::fmpz)
   (a > typemax(UInt) || a < 0) && throw(InexactError(:convert, UInt, a))
   return ccall((:fmpz_get_ui, libflint), UInt, (Ref{fmpz}, ), a)
end

convert(::Type{UInt}, a::fmpz) = UInt(a)

function (::Type{Float64})(n::fmpz)
    # rounds to zero
    ccall((:fmpz_get_d, libflint), Float64, (Ref{fmpz},), n)
end

convert(::Type{Float64}, n::fmpz) = Float64(n)

(::Type{Float32})(n::fmpz) = Float32(Float64(n))

convert(::Type{Float32}, n::fmpz) = Float32(n)

(::Type{Float16})(n::fmpz) = Float16(Float64(n))

convert(::Type{Float16}, n::fmpz) = Float16(n)

(::Type{BigFloat})(n::fmpz) = BigFloat(BigInt(n))

convert(::Type{BigFloat}, n::fmpz) = BigFloat(n)

Base.promote_rule(::Type{fmpz}, ::Type{T}) where {T <: Integer} = fmpz

promote_rule(::Type{fmpz}, ::Type{T}) where {T <: Integer} = fmpz
