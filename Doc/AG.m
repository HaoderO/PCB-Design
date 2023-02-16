clc;
clear all; 
img=imread('2.jpg');
%把图片转换为灰度图 
gray_img = rgb2gray(img);
%计算图片的梯度 
[Gx,Gy] = imgradientxy(gray_img);
%计算梯度的平均值 
mean_Gx = mean(Gx(:)); mean_Gy = mean(Gy(:));
%显示结果 
fprintf('The mean gradient of the image is (%f, %f)\n',mean_Gx,mean_Gy);