clc;
clear; 
% 读取图像 
I = imread('1.jpg');
% 生成灰度图像 
Igray = rgb2gray(I);
% 计算信息熵 
[m,n] = size(Igray); p=zeros(1,256); 
for i=1:m 
    for j=1:n 
        p(Igray(i,j)+1)=p(Igray(i,j)+1)+1; 
    end
end
p = p./(m*n);
entropy = 0;
for i=1:length(p) 
    if p(i) > 0 
        entropy = entropy - p(i)*log2(p(i)); 
    end
end
fprintf('The entropy of image is %f.\n', entropy);

% % Matlab script to display image information entropy
% % Read in the image 
% I = imread('1.jpg');
% % Calculate the information entropy of the image 
% H = entropy(I);
% % Display the results 
% fprintf('The information entropy of the image is %.2f\n', H);