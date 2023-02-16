clc; %清理命令行窗口
clear all; %清理工作区

% 为了将图片转换为RGB888模式的文本文件
% 读取图像 
img = imread('180_180.jpeg');
% 获取尺寸 
[m,n,~] = size(img);
% 创建文件 
fileID = fopen('RGB888_mode.txt','w');
% 循环写入RGB888数据 
for i=1:m 
    for j=1:n 
        r = img(i,j,1); 
        g = img(i,j,2); 
        b = img(i,j,3); 
%         fprintf(fileID,'0x%.2X',b); 
%         fprintf(fileID,'%.2X',g); 
        fprintf(fileID,'%.2X%.2X%.2X ',r,g,b); 
    end
end
% 关闭文件 
fclose(fileID);