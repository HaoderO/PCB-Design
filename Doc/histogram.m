clc;
clear; 
%读取图片 
I = imread('5.jpg'); 
%计算灰度图信息 
gray_scale = rgb2gray(I); 
%计算直方图 
[counts,binLocations] = imhist(gray_scale); 
%显示直方图 
bar(binLocations,counts);