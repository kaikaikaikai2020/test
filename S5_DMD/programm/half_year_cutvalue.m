function v = half_year_cutvalue(x)
x = sort(x);
v = x(round(end/10));
end