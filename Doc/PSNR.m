clc;
clear; 
% 计算图片的峰值信噪比（PSNR） 
% 该脚本文件用于计算图片的峰值信噪比（PSNR） 
% 两幅图片 
Original_image = imread('2.jpg');
Processed_image = imread('3.jpg');
% 计算两幅图片的MSE 
mse_image = (double(Original_image) - double(Processed_image)).^2; 
mse_value = mean(mse_image(:));
% 计算峰值信噪比（PSNR） 
max_pixel = max(double(Original_image(:)));
result = 10*log10(max_pixel^2/mse_value);
% 打印峰值信噪比（PSNR） 
fprintf('PSNR of two images: %.2f dB\n', result);