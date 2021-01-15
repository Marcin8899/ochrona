clc;
clear;
close all;
image = imread('.\obrazy\baboon.jpg');

Rr = double(image(:,:,1))./255;
Gg = double(image(:,:,2))./255;
Bb = double(image(:,:,3))./255;

dct_red = dct2(Rr);
dct_green = dct2(Gg);
dct_blue = dct2(Bb);

[N,M] = size(dct_red);

liczn_red = 0;
liczn_green = 0;
liczn_blue = 0;

for i=1:N
    for j=1:M
        if(abs(dct_red(i,j)) <= 0.43)
            dct_red(i,j) = 0.0;
            liczn_red = liczn_red+1;
        end
        if(abs(dct_green(i,j)) <= 0.15)
            dct_green(i,j) = 0.0;
            liczn_green = liczn_green+1;
        end
        if(abs(dct_blue(i,j)) <= 0.43)
            dct_blue(i,j) = 0.0;
            liczn_blue = liczn_blue+1;
        end
    end
end

b1 = idct2(dct_red);
b2 = idct2(dct_green);
b3 = idct2(dct_blue);

zer_wsp_red = liczn_red/(N*M) * 100;
fprintf('Wyzerowano  %2.1f współczynników składowej Red \n\n', zer_wsp_red);
zer_wsp_green = liczn_green/(N*M) * 100;
fprintf('Wyzerowano  %2.1f współczynników składowej Green \n\n', zer_wsp_green);
zer_wsp_blue = liczn_blue/(N*M) * 100;
fprintf('Wyzerowano  %2.1f współczynników składowej Blue \n\n', zer_wsp_blue);

figure(1)
imshow(image);
title('Obraz Oryginalny')

B1 = cat(3,b1,b2,b3);
figure(2)
imshow(B1);
title('Obraz po kompresji')

rb1=abs(Rr-b1);
rb1_norm = rb1./max([abs(max(rb1)) abs(min(rb1))]);
rb2=abs(Gg-b2);
rb2_norm = rb2./max([abs(max(rb2)) abs(min(rb2))]);
rb3=abs(Bb-b3);
rb3_norm = rb3./max([abs(max(rb3)) abs(min(rb3))]);

figure(3)
imshow(rb1_norm);
title('Różnice R')

figure(4)
imshow(rb2_norm);
title('Różnice G')

figure(5)
imshow(rb3_norm);
title('Różnice B')
        
