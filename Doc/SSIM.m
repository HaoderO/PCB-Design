clc; 
clear;
% 读取图像并转换为灰度图 
img1 = imread('2.jpg'); 
img1 = rgb2gray(img1);
img2 = imread('processed.jpg'); 
img2 = rgb2gray(img2);
% 计算图像的结构相似性，并显示 
similarity = ssim(img1, img2); 
fprintf('图像的结构相似性为：%f\n',similarity);