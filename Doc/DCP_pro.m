clc;
clear all;
close all;
J = imread('1.jpg');
J = double(J);
J = J ./255 ;
figure(1); imshow(J); 
% 求暗通道图像 Jdark = min(min());
Jdark = Idark(J);
figure(2);imshow(Jdark,[]);
 
%
% 注意：何凯明使用了soft matting方法对得到的粗透射率Jt进行细化 
%       本代码采用梯度导向滤波实现
Jdark = gradient_guidedfilter(Jdark,Jdark, 0.04);
figure(3);imshow(Jdark,[]);
% 大气物理模型 J = I*t + A*(1-t)  【直接衰减项】+【大气光照】
% 透射率 t与深度的关系 t=exp(-a*depth)
w = 0.95;         %雾的保留系数
Jt = 1 - w*Jdark; %求解透射率
 
% 求解全局大气光照
% 1.首先对输入的有雾图像I求解其暗通道图像Jdark。
% 2.选择Jdark总像素点个数千分之一（N/1000）个最亮的像素点，记录像素点（x,y）坐标
% 3.根据点的坐标分别在原图像J的三个通道（r,g,b）内找到这些像素点并加和得到（sum_r,sum_g,sum_b）.
% 4.Ac=[Ar,Ag,Ab]. 其中Ar=sum_r/N;   Ag=sum_g/N;   Ab=sum_b/N.
[m,n,~] = size(J);
N = floor( m*n./1000 );
MaxPos = [0,0]; % 初始化
for i=1:1:N
    MaxValue = max(max(Jdark));
    [x,y] = find(Jdark==MaxValue);
    Jdack(Jdark==MaxValue) = 0; %最大值置零，寻找下一次次大值
    %检查长度
    MaxPos = vertcat(MaxPos,[x,y]);
    Cnt = length(MaxPos(1));
    if Cnt > N
        break;
    end
end
MaxPosN = MaxPos(2:N+1,:);
 
Rsum = 0;  Jr = J(:,:,1);
Gsum = 0;  Jg = J(:,:,2);
Bsum = 0;  Jb = J(:,:,3);
for j=1:1:N
    Rsum = Rsum + Jr(MaxPosN(j,1),MaxPosN(j,2));
    Gsum = Gsum + Jg(MaxPosN(j,1),MaxPosN(j,2));
    Bsum = Bsum + Jb(MaxPosN(j,1),MaxPosN(j,2));
end
 
Ac = [Rsum/N, Gsum/N, Bsum/N];
 
% 求解清晰的图像
% 根据 J = I*t + A*(1-t)   I = (J-A)/Jt + A
Iorg = zeros(m,n,3);
for i = 1:1:m
    for j = 1:1:n
        for k = 1:1:3
        Iorg(i,j,k) = (J(i,j,k)-Ac(k)) ./ Jt(i,j) + Ac(k);
        end
    end
end
figure(4); imshow(Iorg,[]);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function Jdark = Idark( I )
% output： Jdark = min(min(r),min(g),min(b));
Wnd = 3;
Ir = I(:,:,1);
Ig = I(:,:,2);
Ib = I(:,:,3);
% 图像拓展
[m,n,~] = size(I);
Irr = zeros(m+Wnd-1, n+Wnd-1); 
Irr((Wnd-1)/2 : m+(Wnd-1)/2-1 , (Wnd-1)/2 : n+(Wnd-1)/2-1 ) = Ir;
Igg = zeros(m+Wnd-1, n+Wnd-1); 
Igg((Wnd-1)/2 : m+(Wnd-1)/2-1 , (Wnd-1)/2 : n+(Wnd-1)/2-1 ) = Ig;
Ibb = zeros(m+Wnd-1, n+Wnd-1); 
Ibb((Wnd-1)/2 : m+(Wnd-1)/2-1, (Wnd-1)/2 : n+(Wnd-1)/2-1 ) = Ib;
% 暗通道
for i=1:1:m
    for j=1:1:n
        Rmin = min(min ( Irr(i:i+Wnd-1, j:j+Wnd-1) ));
        Gmin = min(min ( Igg(i:i+Wnd-1, j:j+Wnd-1) ));
        Bmin = min(min ( Ibb(i:i+Wnd-1, j:j+Wnd-1) ));
        Jdark(i,j) = min(min(Rmin,Gmin),Bmin);
    end
end
 
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function q = gradient_guidedfilter(I, p, eps)  
%   GUIDEDFILTER   O(1) time implementation of guided filter.  
%  
%   - guidance image: I (should be a gray-scale/single channel image)  
%   - filtering input image: p (should be a gray-scale/single channel image)  
%   - regularization parameter: eps  
  
r=16;  
[hei, wid] = size(I);  
N = boxfilter(ones(hei, wid), r); % the size of each local patch; N=(2r+1)^2 except for boundary pixels.  
  
mean_I = boxfilter(I, r) ./ N;  
mean_p = boxfilter(p, r) ./ N;  
mean_Ip = boxfilter(I.*p, r) ./ N;  
cov_Ip = mean_Ip - mean_I .* mean_p; % this is the covariance of (I, p) in each local patch.  
  
mean_II = boxfilter(I.*I, r) ./ N;  
var_I = mean_II - mean_I .* mean_I;  
  
%weight  
epsilon=(0.001*(max(p(:))-min(p(:))))^2;  
r1=1;  
  
N1 = boxfilter(ones(hei, wid), r1); % the size of each local patch; N=(2r+1)^2 except for boundary pixels.  
mean_I1 = boxfilter(I, r1) ./ N1;  
mean_II1 = boxfilter(I.*I, r1) ./ N1;  
var_I1 = mean_II1 - mean_I1 .* mean_I1;  
  
chi_I=sqrt(abs(var_I1.*var_I));      
weight=(chi_I+epsilon)/(mean(chi_I(:))+epsilon);       
  
gamma = (4/(mean(chi_I(:))-min(chi_I(:))))*(chi_I-mean(chi_I(:)));  
gamma = 1 - 1./(1 + exp(gamma));  
  
%result  
a = (cov_Ip + (eps./weight).*gamma) ./ (var_I + (eps./weight));   
b = mean_p - a .* mean_I;   
  
mean_a = boxfilter(a, r) ./ N;  
mean_b = boxfilter(b, r) ./ N;  
  
q = mean_a .* I + mean_b;   
end  

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function imDst = boxfilter(imSrc, r)  
  
%   BOXFILTER   O(1) time box filtering using cumulative sum  
%  
%   - Definition imDst(x, y)=sum(sum(imSrc(x-r:x+r,y-r:y+r)));  
%   - Running time independent of r;   
%   - Equivalent to the function: colfilt(imSrc, [2*r+1, 2*r+1], 'sliding', @sum);  
%   - But much faster.  
  
[hei, wid] = size(imSrc);  
imDst = zeros(size(imSrc));  
  
%cumulative sum over Y axis  
imCum = cumsum(imSrc, 1);  
%difference over Y axis  
imDst(1:r+1, :) = imCum(1+r:2*r+1, :);  
imDst(r+2:hei-r, :) = imCum(2*r+2:hei, :) - imCum(1:hei-2*r-1, :);  
imDst(hei-r+1:hei, :) = repmat(imCum(hei, :), [r, 1]) - imCum(hei-2*r:hei-r-1, :);  
  
%cumulative sum over X axis  
imCum = cumsum(imDst, 2);  
%difference over X axis  
imDst(:, 1:r+1) = imCum(:, 1+r:2*r+1);  
imDst(:, r+2:wid-r) = imCum(:, 2*r+2:wid) - imCum(:, 1:wid-2*r-1);  
imDst(:, wid-r+1:wid) = repmat(imCum(:, wid), [1, r]) - imCum(:, wid-2*r:wid-r-1);  
end  