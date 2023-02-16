clc; %清理命令行窗口
clear all; %清理工作区

%读取图片 
I=imread('2.jpg');
%将图片转换为16位无符号整型 
I_16=uint16(I); 
%右移3位，除以8 
R=bitshift(I_16(:,:,1), -3); 
%右移2位，除以4 
G=bitshift(I_16(:,:,2), -2); 
%右移3位，除以8
B=bitshift(I_16(:,:,3), -3);
%将R、G、B位移到正确的位置并进行或运算
RGB565=bitor(bitor(bitshift(R,11),bitshift(G,5)), B); 
%获取图片的长宽
[m,n] = size(RGB565); 
fid=fopen('RGB565_mode.txt','wt'); 
for i=1:m 
    for j=1:n 
        fprintf(fid,'%X ',RGB565(i,j)); 
    end
  %  fprintf(fid,'\n');
end
fclose(fid);