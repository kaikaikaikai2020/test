clear
[~,b_M05,b_M15,b_M30 ]= choose_data(3);
figure
subplot(3,2,1)
plot(b_M30(2:400,1))
title('SV1F-Model30');
subplot(3,2,2)
plot(b_M30(401:end,1))
title('SV1F-Val30');

subplot(3,2,3)
plot(b_M15(2:800,1))
title('SV1F-Model15');
subplot(3,2,4)
plot(b_M15(801:end,1))
title('SV1F-Val15');

subplot(3,2,5)
plot(b_M05(2:2400,1))
title('SV1F-Model05');
subplot(3,2,6)
plot(b_M05(2401:end,1))
title('SV1F-Val05');