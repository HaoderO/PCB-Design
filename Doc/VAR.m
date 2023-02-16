clc; %清理命令行窗口
clear all; %清理工作区
% 读入图片
I = imread('Image.jpg');
% 计算图片的方差
Variance = var(double(I(:)));
% 输出结果
fprintf('图片方差为：%f\n', Variance);