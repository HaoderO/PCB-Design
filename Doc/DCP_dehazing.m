
clear all;

close all;

clc;

w0=0.85;%0.65  乘积因子用来保留一些雾，1时完全去雾

t0=0.1;

I=imread('2.jpg');

Ir = I(:,:,1);

[h,w,s]=size(I);

min_I=zeros(h,w);

dark_I = zeros(h,w);

%下面取得暗影通道图像

for i=1:h

for j=1:w

dark_I(i,j)=min(I(i,j,:));

end

end

dark_I = uint8(dark_I);

img_dark = ordfilt2(dark_I,1,ones(3,3));

Max_dark_channel=double(max(max(img_dark)))%天空亮度

dark_channel=double(img_dark);

t1=1-w0*(dark_channel/Max_dark_channel);%取得透谢分布率图

t2=max(t1,t0);

T=uint8(t1*255);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

I1=double(I);

J(:,:,1) = uint8((I1(:,:,1) - (1-t2)*Max_dark_channel)./t2);

J(:,:,2) = uint8((I1(:,:,2) - (1-t2)*Max_dark_channel)./t2);

J(:,:,3) =uint8((I1(:,:,3) - (1-t2)*Max_dark_channel)./t2);

figure,

set(gcf,'outerposition',get(0,'screensize'));

subplot(221),imshow(I),title('原始图像');

subplot(222),imshow(J),title('去雾后的图像');

subplot(223),imshow(img_dark),title('dark channnel的图形');

subplot(224),imshow(T),title('透射率t的图形');

imwrite(J,'wu1.jpg');

