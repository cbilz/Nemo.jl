@testset "nmod_poly.constructors" begin
  R = ResidueRing(ZZ, 17)
  
  S1 = PolyRing(R)
  S2 = PolyRing(R)

  @test isa(S1, NmodPolyRing)
  @test S1 !== S2

  Rx, x = PolynomialRing(R, "x")

  @test elem_type(Rx) == nmod_poly
  @test elem_type(NmodPolyRing) == nmod_poly
  @test parent_type(nmod_poly) == NmodPolyRing
  @test dense_poly_type(nmod) == nmod_poly

  S = ResidueRing(ZZ, 19)
  Sy, y = PolynomialRing(R, "y")

  RRx, xx = PolynomialRing(R, "x")
  RRRx, xxx = PolynomialRing(ResidueRing(ZZ, 17), "xx")

  @test var(Rx) == Symbol("x")

  @test RRx != RRRx

  @test RRx == Rx

  @test S != R

  @test isa(Rx, NmodPolyRing)
  @test isa(x, PolyElem)

  a = Rx()

  @test isa(a, PolyElem)
  @test parent(a) == Rx

  b = Rx(2)

  @test isa(b, PolyElem)
  @test parent(b) == Rx

  c = Rx(UInt(3))

  @test isa(c, PolyElem)
  @test parent(c) == Rx

  d = Rx(fmpz(3))

  @test isa(d, PolyElem)
  @test parent(d) == Rx

  e = Rx(R(16))

  @test isa(e, PolyElem)
  @test parent(e) == Rx

  f = Rx([UInt(1), UInt(2), UInt(3)])

  @test isa(f, PolyElem)
  @test parent(f) == Rx

  g = Rx([fmpz(1), fmpz(2), fmpz(3)])

  @test isa(g, PolyElem)
  @test parent(g) == Rx

  h = Rx([R(1), R(2), R(3)])

  @test isa(h, PolyElem)
  @test parent(h) == Rx

  _a = PolynomialRing(ZZ, "y")[1]([fmpz(1),fmpz(2),fmpz(3)])

  k = Rx(_a)

  @test isa(k, PolyElem)
  @test parent(k) == Rx

  l = x^2 + x^2 + x^2 + x^1 + x^1 + R(1)

  @test isa(l, PolyElem)
  @test parent(l) == Rx

  @test f == g
  @test g == h
  @test h == k
  @test k == l

  m = Rx([1, 2, 3])

  @test isa(m, PolyElem)
end

@testset "nmod_poly.printing" begin
  R = ResidueRing(ZZ, 17)
  Rx, x = PolynomialRing(R, "x")

  a = x^3 + x + 1

  @test sprint(show, "text/plain", a) == "x^3 + x + 1"
end

@testset "nmod_poly.manipulation" begin
  R = ResidueRing(ZZ, 17)
  Rx, x = PolynomialRing(R, "x")

  @test isone(one(Rx))
  @test iszero(zero(Rx))
  @test isgen(gen(Rx))
  @test isunit(one(Rx))

  @test !isunit(gen(Rx))

  @test degree(x) == 1
  @test degree(x^10) == 10

  @test length(x^10) == 11

  @test coeff(x^6 + R(2)*x^5, 5) == R(2)

  @test leading_coefficient(R(3)*x^2 + x) == R(3)

  @test canonical_unit(-x + 1) == R(-1)

  @test deepcopy(one(Rx)) == one(Rx)

  @test var(Rx) == :x

  @test modulus(x) == 17

  @test modulus(R) == 17

  @test characteristic(Rx) == 17
end

@testset "nmod_poly.polynomial" begin
   R = ResidueRing(ZZ, 23)

   f = polynomial(R, [])
   g = polynomial(R, [1, 2, 3])
   h = polynomial(R, fmpz[1, 2, 3])
   k = polynomial(R, [R(1), R(2), R(3)])
   p = polynomial(R, [1, 2, 3], "y")

   @test isa(f, nmod_poly)
   @test isa(g, nmod_poly)
   @test isa(h, nmod_poly)
   @test isa(k, nmod_poly)
   @test isa(p, nmod_poly)

   q = polynomial(R, [1, 2, 3], cached=false)

   @test parent(g) !== parent(q)
end

@testset "nmod_poly.similar" begin
   R = ResidueRing(ZZ, 23)

   f = polynomial(R, [1, 2, 3])
   g = similar(f)
   h = similar(f, "y")

   @test isa(g, nmod_poly)
   @test isa(h, nmod_poly)

   q = similar(g, cached=false)

   @test parent(g) === parent(q)
end

@testset "nmod_poly.unary_ops" begin
  R = ResidueRing(ZZ, 23)
  Rx, x = PolynomialRing(R, "x")

  f = x^2 + R(13)*x + R(5)

  @test -f ==  R(22)*x^2 + R(10)*x + R(18)
end

@testset "nmod_poly.binary_ops" begin
  R = ResidueRing(ZZ, 23)
  Rx, x = PolynomialRing(R, "x")

  f = x^2 + R(13)*x + R(5)
  g = x^3 + R(11)*x^2 + R(10)*x + R(18)
  h = x + R(10)

  @test f + g == x^3 + R(12)*x^2

  @test f*g == x^5 + x^4 + R(20)*x^3 + R(19)*x^2 + R(8)*x + R(21);

  @test f - g == R(22)*x^3 + R(13)*x^2 + R(3)*x + R(10)

  @test h*(f+g) == x^4 + R(22)*x^3 + R(5)*x^2
end

@testset "nmod_poly.adhoc_binary" begin
  R = ResidueRing(ZZ, 113)
  Rx, x = PolynomialRing(R, "x")

  S = ResidueRing(ZZ,112)

  f = x^2 + R(2)x + R(1)
  g = x^3 + R(3)x^2 + x

  @test fmpz(2)*f == R(2)x^2 + R(4)x + R(2)
  @test fmpz(2)*f == f*fmpz(2)
  @test 2*f == fmpz(2)*f
  @test f*2 == 2*f
  @test R(2)*f == fmpz(2)*f
  @test f*R(2) == R(2)*f

  @test_throws ErrorException S(1)*f

  @test f + 112 == x^2 + R(2)x
  @test 112 + f == f + 112
  @test R(112) + f == f + 112
  @test 112 + f == f + R(112)
  @test f + fmpz(112) == f + 112
  @test fmpz(112) + f == f + fmpz(112)

  @test_throws ErrorException S(1)+f

  @test f - 1 == x^2 + R(2)x
  @test fmpz(1) - f == -(f - fmpz(1))
  @test fmpz(1) - f == R(112)*x^2 + R(111)*x
  @test f - R(1) == f - 1
  @test R(1) - f == -(f - R(1))

  @test_throws ErrorException f - S(1)
end

@testset "nmod_poly.powering" begin
  R = ResidueRing(ZZ, 23)
  Rx, x = PolynomialRing(R, "x")

  f = x^2 + R(13)x + R(5)

  @test f^3 == x^6 + 16x^5 + 16x^4 + 11x^3 + 11x^2 + 9x + 10

  @test f^23 == x^46 + 13*x^23 + 5

  @test_throws DomainError f^(-1)
end

@testset "nmod_poly.comparison" begin
  R = ResidueRing(ZZ, 23)
  Rx, x = PolynomialRing(R, "x")
  Ry, y = PolynomialRing(R, "y")

  @test x^2 + x == x^2 + x
  @test_throws ErrorException x^2 + x != y^2 + y
end

@testset "nmod_poly.adhoc_comparison" begin
   R = ResidueRing(ZZ, 7)
   S, x = PolynomialRing(R, "x")

   f = x^2 + 2x + 1

   @test f != 1

   @test 1 != f

   @test S(5) == fmpz(5)

   @test fmpz(5) != f

   @test S(5) == R(5)

   @test R(5) != x + 1
end

@testset "nmod_poly.truncation" begin
  R = ResidueRing(ZZ, 23)
  Rx, x = PolynomialRing(R, "x")

  f = x^5 + x^4 + 2 *x^2

  g = truncate(f,4)

  @test parent(g) == parent(f)

  @test truncate(f,2) == R(0)
  @test truncate(f,5) == x^4 + 2*x^2
  @test truncate(f,10) == f
end

@testset "nmod_poly.mullow" begin
  R = ResidueRing(ZZ, 23)
  Rx, x = PolynomialRing(R, "x")

  f = x^5 + x^4 + 2 *x^2
  g = x^4 + x^3

  @test mullow(f,g,2) == truncate(f*g,2)
  @test mullow(f,g,7) == truncate(f*g,7)
end

@testset "nmod_poly.reverse" begin
  R = ResidueRing(ZZ, 23)
  Rx, x = PolynomialRing(R, "x")

  f = x^5 + x^4 + 2 *x^2 + 1

  g = reverse(f)

  @test parent(g) == parent(f)
  @test g == x^5 + 2*x^3 + x + 1
  @test isone(reverse(x))
end

@testset "nmod_poly.shift" begin
  R = ResidueRing(ZZ, 23)
  Rx, x = PolynomialRing(R, "x")

  f = x^5 + x^4 + 2 *x^2 + 1

  g = shift_left(f,3)
  h = shift_right(f,3)

  @test parent(g) == parent(f)
  @test parent(h) == parent(f)

  @test g == x^3*f

  @test h == x^2 + x

  @test f == shift_right(shift_left(f,20),20)

  @test_throws DomainError shift_left(f,-1)
  @test_throws DomainError shift_right(f,-1)
end

@testset "nmod_poly.division" begin
  R = ResidueRing(ZZ, 23)
  Rx, x = PolynomialRing(R, "x")

  f = x^5 + x^4 + 2 *x^2 + x

  g = divexact(f,x)

  @test parent(g) == parent(f)
  @test g == x^4 + x^3 + 2*x + 1

  g = divexact(f,x+1)

  @test g == x^4 + 2*x + 22

  h = x^1235+x^23

  @test divexact(f*h,h) == f

  @test_throws DivideError divexact(f,zero(Rx))

  @test f - divexact(f,Rx(2))*2 == zero(Rx)

  (q,r) = divrem(f,x+2)

  @test parent(q) == parent(f)
  @test parent(r) == parent(f)

  @test (q,r) == (x^4 + 22*x^3 + 2*x^2 + 21*x + 5, Rx(13))
  @test f == q*(x+2) + r

  @test_throws DivideError divrem(f,zero(Rx))

  r = rem(f,x+3)

  @test parent(r) == parent(f)

  @test r == Rx(14)
end

@testset "nmod_poly.adhoc_exact_division" begin
   R = ResidueRing(ZZ, 23)
   S, x = PolynomialRing(R, "x")

   f = x^2 + 2x + 1

   @test divexact(3*f, fmpz(3)) == f

   @test divexact(3*f, 3) == f

   @test divexact(R(7)*f, R(7)) == f
end

@testset "nmod_poly.gcd" begin
  R = ResidueRing(ZZ, 23)
  Rx, x = PolynomialRing(R, "x")

  f = x^5 + x^4 + 2 *x^2 + x
  g = x^3 + x^2 + x

  k = gcd(f,g)

  @test parent(k) == parent(x)
  @test k == x

  k, s, t = gcdx(f,g)

  @test k == s*f + t*g
end

@testset "nmod_poly.modular_arithmetic" begin
  R = ResidueRing(ZZ, 487326487)
  S, x = PolynomialRing(R, "x")

  f = 3*x^2 + x + 2
  g = 5*x^2 + 2*x + 1
  h = 3*x^3 + 2*x^2 + x + 7

  @test gcdinv(f, g) == (1,84344969*x+234291581)

  @test invmod(f, h) == 40508247*x^2+341251293*x+416130174

  @test mulmod(f, g, h) == 324884334*x^2+162442132*x+162442162

  @test powermod(f, 10, h) == 485924368*x^2+380106591*x+302530457

  @test powermod(f, -10, g) == 484381224*x+14566177
end

@testset "nmod_poly.resultant" begin
  R = ResidueRing(ZZ, 23)
  Rx, x = PolynomialRing(R, "x")

  f = x^5 + x^4 + 2 *x^2 + x

  @test resultant(f,x) == Rx(0)

  g = resultant(f,x^2 +2)

  @test parent(g) == R

  @test g == 4
end

@testset "nmod_poly.evaluate" begin
  R = ResidueRing(ZZ, 23)
  Rx, x = PolynomialRing(R, "x")

  f = x^5 + x^4 + 2 *x^2 + x

  r = evaluate(f, R(20))
  s = evaluate(f, 20)
  t = evaluate(f, fmpz(20))

  @test r == R(14)

  @test s == R(14)

  @test t == R(14)

if VERSION >= v"0.5.0-dev+3171"

  @test f(R(20)) == R(14)

  @test f(20) == R(14)

  @test f(fmpz(20)) == R(14)
end
end

@testset "nmod_poly.derivative" begin
  R = ResidueRing(ZZ, 23)
  Rx, x = PolynomialRing(R, "x")

  f = x^5 + x^4 + 2 *x^2 + x

  ff = derivative(f)

  @test parent(ff) == parent(f)

  @test ff == 5*x^4 + 4*x^3 + 4*x + 1
end

@testset "nmod_poly.integral" begin
  R = ResidueRing(ZZ, 7)
  S, x = PolynomialRing(R, "x")

  f = x^2 + 2x + 1

  @test integral(f) == 5x^3 + x^2 + x
end

@testset "nmod_poly.compose" begin
  R = ResidueRing(ZZ, 23)
  Rx, x = PolynomialRing(R, "x")

  f = x^5 + x^4 + 2 *x^2 + x
  g = x+1

  ff = compose(f,g)

  @test parent(ff) == parent(f)

  @test ff == x^5 + 6*x^4 + 14*x^3 + 18*x^2 + 14*x + 5
end

@testset "nmod_poly.interpolate" begin
  R = ResidueRing(ZZ, 23)
  Rx, x = PolynomialRing(R, "x")

  xval = [ R(0), R(1), R(2), R(3) ]

  yval = [ R(0), R(1), R(4), R(9) ]

  f = interpolate(Rx,xval,yval)

  @test parent(f) == Rx
  @test f == x^2
end

@testset "nmod_poly.inflate" begin
  R = ResidueRing(ZZ, 23)
  Rx, x = PolynomialRing(R, "x")

  f = x^6 + x^4 + 2 *x^2

  g = inflate(f,2)

  @test parent(g) == parent(f)
  @test g == x^12 + x^8 + 2*x^4

  @test_throws DomainError inflate(f,-1)
end

@testset "nmod_poly.deflate" begin
  R = ResidueRing(ZZ, 23)
  Rx, x = PolynomialRing(R, "x")

  f = x^6 + x^4 + 2 *x^2

  g = deflate(f,2)

  @test parent(g) == parent(f)
  @test g == x^3 + x^2 + 2*x

  @test_throws DomainError deflate(f,-1)
end

@testset "nmod_poly.lifting" begin
  R = ResidueRing(ZZ, 23)
  Rx, x = PolynomialRing(R, "x")
  Zy,y = PolynomialRing(ZZ, "y")

  f = x^6 + x^4 + 2 *x^2

  Zf = lift(Zy, f)

  @test Rx(Zf) == f
end

@testset "nmod_poly.isirreducible" begin
  R = ResidueRing(ZZ, 23)
  Rx, x = PolynomialRing(R, "x")

  f = x^6 + x^4 + 2 *x^2

  @test !isirreducible(f)

  @test isirreducible(x)

  @test isirreducible(x^16+2*x^9+x^8+x^2+x+1)
end

@testset "nmod_poly.issquarefree" begin
  R = ResidueRing(ZZ, 23)
  Rx, x = PolynomialRing(R, "x")

  f = x^6 + x^4 + 2 *x^2

  @test !issquarefree(f)

  @test issquarefree((x+1)*(x+2)*(x+3))
end

@testset "nmod_poly.factor" begin
  R = ResidueRing(ZZ, 23)
  Rx, x = PolynomialRing(R, "x")

  f = 2*((x^6 + x^4 + 2 *x^2 )^10 + x - 1)

  fac = factor(f)

  @test f == unit(fac)*prod([ p^e for (p, e) in fac])
  p = unit(fac)

  sh = factor_shape(f)

  @test sh == Dict(36=>1,1=>1,4=>1,19=>1)

  f = 5*(x^6 + x^4 + 2 *x^2 )^10

  fac = factor_squarefree(f)

  @test f == unit(fac) * prod([ p^e for (p, e) in fac])

  @test_throws ErrorException factor_distinct_deg(f)

  fac = factor_distinct_deg(x* (x^2 + 1)*(x^2 + 2)*(x+1))

  @test fac == Dict(2=>x^4+3*x^2+2,1=>x^2 + x)
end

@testset "nmod_poly.canonicalization" begin
  R = ResidueRing(ZZ, 23)
  Rx, x = PolynomialRing(R, "x")

  @test canonical_unit(5*x) == R(5)
end

@testset "nmod_poly.remove_valuation" begin
  R = ResidueRing(ZZ, 23)
  Rx, x = PolynomialRing(R, "x")

  f = (x + 1)^10 * (x + 2) * (x + 3)
  g = x + 1

  @test_throws Exception remove(f, zero(Rx))
  @test_throws Exception remove(f, one(Rx))
  @test_throws Exception remove(zero(Rx), g)

  n, p = remove(f, g)

  @test n == valuation(f, g)
  @test n == 10
  @test p == (x+2)*(x+3)

   v, q = divides(f*g, f)

   @test v
   @test q == g

   v, q = divides(f*g + 1, f)

   @test !v
end
