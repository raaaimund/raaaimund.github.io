---
layout:     post
title:      Linear differential equation of order one
date:       2020-01-27 04:20
author:     Raimund Rittnauer
description:    How to solve linear differential equations of order one
categories: math
comments: true
tags:
 - differential
---

General form of a [linear differential equation of order one][1]{:target="_blank"}

$$ y' + ya(x) = s(x) $$

The equation is called homogeneous when $$s(x) = 0$$ otherwise it is called inhomogeneous.

To solve such type of equation we need $$ y_h(x) $$ and $$y_p(x)$$.

$$ y(x) = y_h(x) + y_p(x) $$

### $$y_h(x)$$

Where $$y_h(x)$$ is the solution of the homogeneous linear differential equation with the form

$$ y' + ya(x) = 0 $$

To get $$y_h(x)$$ we have to separate x and y and calculate the integral for both sides

$$ \frac{dy}{dx} + ya(x) = 0 $$

$$ dy+ya(x)dx = 0 $$

$$ \frac{dy}{y} + a(x)dx = 0 $$

The next step is called [separation of variables][2]{:target="_blank"}

$$ \frac{dy}{y} = -a(x)dx $$

$$ \int \frac{1}{y}dy = - \int a(x)dx $$

$$ ln|y| = - \int a(x)dx + C $$

$$ y = C * e^{- \int a(x)dx} $$

for $$C = \pm e^{C_0}$$, $$C_0 \epsilon \R$$ and wee need $$C = 0$$ for $$y = 0$$, because $$e^x \ne 0$$.

Now we can solve $$y_h(x)$$

$$ y_h(x) = C * e^{- \int a(x)dx} $$

### $$y_p(x)$$

To get a particular solution $$y_p(x)$$ we have to change our constant $$C$$ to a function $$C(x)$$. This step is called [variation of constants][3]{:target="_blank"}.

$$ y_p(x) = C(x) * e^{- \int a(x)dx} $$

In the original equation we can replace $$y'$$ with $$y_p'(x)$$ and $$y$$ with $$y_p(x)$$.

$$ y_p'(x) + y_p(x)a(x) = s(x) $$

$$ C'(x) * (e^{- \int a(x)dx}) + C(x) * e^{- \int a(x)dx}*a(x) = s(x) $$

$$ C'(x) * e^{- \int a(x)dx} - C(x)*e^{- \int a(x)dx}*a(x) + C(x) * e^{- \int a(x)dx}*a(x) = s(x) $$

$$ C'(x) = s(x)e^{\int a(x)dx} $$

$$ C(x) = \int s(x)e^{\int a(x)dx}dx $$

### $$y(x)$$

Now we can solve our equation

$$ y(x) = y_h(x) + y_p(x) $$

$$ y(x) = C * e^{- \int a(x)dx} + C(x) * e^{- \int a(x)dx} $$

[1]: https://en.wikipedia.org/wiki/Linear_differential_equation
[2]: https://en.wikipedia.org/wiki/Separation_of_variables
[3]: https://en.wikipedia.org/wiki/Linear_differential_equation#Non-homogeneous_equation_with_constant_coefficients