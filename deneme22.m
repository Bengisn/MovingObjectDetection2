clear all;
close all;
clc;

videoObject = VideoReader('kayit19.mp4');

numOfAveragedFrames = 5;
numOfFramesInTheVideo = floor(videoObject.Duration) * floor(videoObject.FrameRate) ;

frame = zeros(videoObject.Height,videoObject.Width,3);
previousFrame = zeros(videoObject.Height,videoObject.Width,3);

for i = 1:1:500
    if i <= numOfAveragedFrames
       previousFrame = previousFrame + double(read(videoObject,i));
       if i == numOfAveragedFrames
           previousFrame = floor(previousFrame/numOfAveragedFrames);
       end
    else
        if mod(i,numOfAveragedFrames) == 0
            frame = frame + double(read(videoObject,i));
            frame = floor(frame/numOfAveragedFrames);
            
            % islemler burda olacak
            diffFrame = frame - previousFrame;
            minValue = min(min(min(diffFrame)));
            maxValue = max(max(max(diffFrame)));
            % rescale of diffFrame
            %diffFrame = rescale(diffFrame, 0, 255, 'InputMin', minValue, 'InputMax', maxValue); 
            diffFrame = floor(0 + (diffFrame - minValue)./(maxValue - minValue).* (255 - 0));
            
           %segmentation for object detection
           %TRIANGLE ALGORITHM
           hist = zeros(1, 256);
           
%            %diffFramelerin histogramini bulmak
%            for m=1:1:size(diffFrame(:,:,1),1)
%                for n=1:1:size(diffFrame(:,:,1),2)
%                    hist(diffFrame(m,n,1)+1) = hist + 1;
%                end
%            end
           
           %histogrami bulmak icin 2.yol
           for m=1:1:length(hist)
              hist(m) = sum(sum(diffFrame(:,:,1) == (m-1)));   
           end
           %plot(hist)
           
           [h_bmax, bmax] = max(hist);
           [h_bmin, bmin] = min(hist);
           
           n=1;
           %(n,hist(n))
           dnew = (abs((h_bmax-h_bmin)*n - (bmax-bmin)*hist(n) + bmin*(h_bmax-h_bmin) + h_bmin*(bmax-bmin)))/sqrt((h_bmax-h_bmin)^2 + (bmax-bmin)^2);
           for n = (bmin+1):1:bmax
               d = (abs((h_bmax-h_bmin)*n - (bmax-bmin)*hist(n) + bmin*(h_bmax-h_bmin) + h_bmin*(bmax-bmin)))/sqrt((h_bmax-h_bmin)^2 + (bmax-bmin)^2);
               if d > dnew
                  dnew = d; 
                  nNew = n;
               end
           end
           
           teta = nNew;
           diffFrame(diffFrame <= teta) = 0;
           diffFrame(diffFrame > teta) = 255;
           image(diffFrame(:,:,1));
           colormap(gray(256))
           pause(2)
           clf
%            n = 1;
%            dnew = ((h_bmax - h_bmin)*n - (bmax-bmin)*hist(n))/ sqrt((h_bmax-h_bmin)^2 + (bmax-bmin)^2);
%            
%            for n = (bmin+1):1:bmax
%                d = ((h_bmax - h_bmin)*n - (bmax-bmin)*hist(n))/ sqrt((h_bmax-h_bmin)^2 + (bmax-bmin)^2); 
%                if d > dnew
%                    dnew = d;
%                end
%            end
%            
%            teta = dnew;
%            diffFrame(diffFrame <= teta) = 0;
%            diffFrame(diffFrame > teta) = 255;
%            image(diffFrame(:,:,1));
%            colormap(gray(256))
%            pause(2)
%            clf 

%             % segmentation for object detection
%             %ISODATA ALGORITHM
%             teta0 = 128;
%             %foreground segmentation
%             mf0 = mean(diffFrame(diffFrame(:,:,1) > teta0)); %128den buyuk olanlarin ortalamasi alindi = foreground segmentation
%             %background segmentation 
%             mb0 = mean(diffFrame(diffFrame(:,:,1) <= teta0)); %128den kucuk olanlarin ortalamasi alindi = background segmentation
%             teta1 = (mf0 + mb0) / 2;
%             
%             while abs(teta0 - teta1)<0.0001
%                 teta0 = teta1; %yeni teta0, teta1 olmus oldu
%                 mf1 = mean(diffFrame(diffFrame(:,:,1) > teta1)); %teta1'den buyuk piksellerin ortalamasini al
%                 mb1 = mean(diffFrame(diffFrame(:,:,1) >= teta1)); %teta1'den kucuk piksellerin ortalamasini al
%                 teta1 = (mf1 + mb1) / 2;
%             end
%             teta1 = floor(teta1)+10;
%             
%             diffFrame(diffFrame <= teta1) = 0;
%             diffFrame(diffFrame > teta1) = 255;
%             
%             image(diffFrame(:,:,1));
%             colormap(gray(256))
%             pause(2)
%             clf
            
            previousFrame = frame;
            frame = zeros(videoObject.Height,videoObject.Width,3);
        else
            frame = frame + double(read(videoObject,i));
        end
    end
    
    
    
    
    
end

