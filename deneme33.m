clear all;
close all;
clc;

videoObject = VideoReader('kayit19.mp4');

numOfAveragedFrames = 10;
numOfFramesInTheVideo = floor(videoObject.Duration) * floor(videoObject.FrameRate) ;

frame = zeros(videoObject.Height,videoObject.Width,3);
previousFrame = zeros(videoObject.Height,videoObject.Width,3);

for i = 1:1:numOfFramesInTheVideo
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
            
            %histogrami bulmak icin
            hist = zeros(1, 256);
            for m=1:1:length(hist)
                hist(m) = sum(sum(diffFrame(:,:,1) == (m-1)));
            end
            %plot(hist)
            
            %segmentation for object detection
            %ISODATA ALGORITHM
            teta0 = 128;
            %foreground segmentation
            mf0 = mean(diffFrame(diffFrame(:,:,1) > teta0)); %128den buyuk olanlarin ortalamasi alindi = foreground segmentation
            %background segmentation
            mb0 = mean(diffFrame(diffFrame(:,:,1) <= teta0)); %128den kucuk olanlarin ortalamasi alindi = background segmentation
            teta1 = (mf0 + mb0) / 2;
            
            while abs(teta0 - teta1)<0.0001
                teta0 = teta1; %yeni teta0, teta1 olmus oldu
                mf1 = mean(diffFrame(diffFrame(:,:,1) > teta1)); %teta1'den buyuk piksellerin ortalamasini al
                mb1 = mean(diffFrame(diffFrame(:,:,1) >= teta1)); %teta1'den kucuk piksellerin ortalamasini al
                teta1 = (mf1 + mb1) / 2;
            end
            teta1 = floor(teta1)+10;
            
            diffFrame(diffFrame <= teta1) = 0;
            diffFrame(diffFrame > teta1) = 255;
            
            figure(1)
            subplot(1,2,1);
            image(diffFrame(:,:,1));
            colormap(gray(256))
            
            %segmentation'dan sonra dilation ve erosion
            
            %create Structuring element
            se = strel('disk',1);
            
            %show erosion
            %erosian every object pixel that touches a background
            %pixel is changed into a background pixel
            frame_erode = imerode(diffFrame(:,:,1),se);
            frame_erode = imerode(frame_erode,se);
            
            %show dilation
            %dilation every background pixel that touches an object
            %pixel is changed into an object pixel
            frame_dilate = imdilate(frame_erode, se);
            frame_dilate = imdilate(frame_dilate, se);
            %bir opening bir closing yaparsan bir dilation 1 erosion oluyor
           
            subplot(1,2,2);
            image(frame_dilate);
            colormap(gray(256))
            pause(0.25)
            
            previousFrame = frame;
            frame = zeros(videoObject.Height,videoObject.Width,3);
            
        else
            frame = frame + double(read(videoObject,i));
        end
    end
    
end