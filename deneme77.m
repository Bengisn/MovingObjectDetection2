clear all;
close all;
clc;

videoObject = VideoReader('kayit19.mp4');

numOfAveragedFrames = 10;
numOfFramesInTheVideo = floor(videoObject.Duration) * floor(videoObject.FrameRate) ;

frame = zeros(videoObject.Height,videoObject.Width,3);
previousFrame = zeros(videoObject.Height,videoObject.Width,3);
tracks = {};
tentativeTracks = {};
for i = 1:1:numOfFramesInTheVideo%numOfFramesInTheVideo
    if i <= numOfAveragedFrames
        previousFrame = previousFrame + double(read(videoObject,i));
        if i == numOfAveragedFrames
            previousFrame = floor(previousFrame/numOfAveragedFrames);
        end
    else
        if mod(i,numOfAveragedFrames) == 0
            frame = frame + double(read(videoObject,i));
            frame = floor(frame/numOfAveragedFrames);  
            %% islemler burda olacak
            diffFrame = frame - previousFrame;
            minValue = min(min(min(diffFrame)));
            maxValue = max(max(max(diffFrame)));
            
            %% rescale of diffFrame
            %diffFrame = rescale(diffFrame, 0, 255, 'InputMin', minValue, 'InputMax', maxValue);
            diffFrame = floor(0 + (diffFrame - minValue)./(maxValue - minValue).* (255 - 0));
            
            %% histogrami bulmak icin
            hist = zeros(1, 256);
            for m=1:1:length(hist)
                hist(m) = sum(sum(diffFrame(:,:,1) == (m-1)));
            end
            %plot(hist)
            
            %% segmentation for object detection
            % ISODATA ALGORITHM
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
            %% segmentation'dan sonra dilation ve erosion
            %create Structuring element
            se = strel('disk',1);
            
            %% erosion
            %erosion every object pixel that touches a background
            %pixel is changed into a background pixel
            frame_erode = imerode(diffFrame(:,:,1),se);
            frame_erode = imerode(frame_erode,se);
            
            %% dilation
            %dilation every background pixel that touches an object
            %pixel is changed into an object pixel
            frame_dilate = imdilate(frame_erode, se);
            frame_dilate = imdilate(frame_dilate, se);
            %bir opening bir closing yaparsan bir dilation 1 erosion oluyor
            
            subplot(1,2,2); % dilaed image of the above
            image(frame_dilate);
            colormap(gray(256))
            pause(0.25)
            
            %% binarize the image
            binaryImage = im2bw(frame_dilate); %binary image halini olusturmus oldum
            %%
            binaryImage = imfill(binaryImage, 'holes');
            %% label and get regionprops
            [labeledImage, numberOfObjects] = bwlabel(binaryImage);
            stats = regionprops(binaryImage, 'BoundingBox', 'Centroid', 'Orientation'); %measure properties of image regions such as: 'Area', 'Centroid', 'Box'
            
            %% tracking
            %kac tane tespit oldugu numberOfObject'te tutuluyor
            %merkez noktalarina stats(x).Centroid ile erisiliyor
            
            availabilityList = ones(1,numberOfObjects);% available 1, available değilse 0 olacak. Bunun için ilerde güncellenecek
          %track cycle
            if size(tracks,2) > 0
                for newTrackCounter = 1:1:numberOfObjects
                   if availabilityList(newTrackCounter) == 1
                      newDetectionX = stats(newTrackCounter).BoundingBox(1);
                      newDetectionY = stats(newTrackCounter).BoundingBox(2);
                      newDetectionXUzunluk = stats(newTrackCounter).BoundingBox(3);
                      newDetectionYUzunluk = stats(newTrackCounter).BoundingBox(4);
                      
                      for TrackCounter = 1:1:size(tracks,2)
                          if tracks{TrackCounter}.isUpdated == 0
                              GateX = tracks{1, TrackCounter}.gateX;
                              GateY = tracks{1, TrackCounter}.gateY;
                              GateXUzunluk = tracks{1, TrackCounter}.gateXUzunluk;
                              GateYUzunluk = tracks{1, TrackCounter}.gateYUzunluk;

                              
                              isIntersected = 0;
                              % kesisim incelemesi, kesisiyorsa isIntersected = 1;
                              A = [newDetectionX, newDetectionY, newDetectionXUzunluk, newDetectionYUzunluk];
                              B = [tentGateX, tentGateY, tentGateXUzunluk, tentGateYUzunluk];
                              area = rectint(A,B);
                                
                             if area >= 1
                                 isIntersected = 1; 
                             end
                             
                             if isIntersected == 1
                                 tracks{1,tentTrackCounter}.isUpdated = 1;
                                 availabilityList(newTentTrackCounter) = 0;
                                 
                                 tracks{1,TrackCounter}.xVeloctiy = newDetectionX - tracks{1,TrackCounter}.x; % in pixels
                                 tracks{1,TrackCounter}.yVeloctiy = newDetectionY - tracks{1,TrackCounter}.y;
                                    
                                 tracks{1,TrackCounter}.xUzunluk = newDetectionXUzunluk; %dikdortgenin x uzunlugu;
                                 tracks{1,TrackCounter}.yUzunluk = newDetectionYUzunluk; %dikdortgenin y uzunlugu
                                 tracks{1,TrackCounter}.x = newDetectionX;  % x uzunlugu
                                 tracks{1,TrackCounter}.y = newDetectionY;  % y uzunlugu
                                 % bunu incelemek gerek, ortadan degil, koseden aciyor
                                 % gate i
                                 tracks{1,TrackCounter}.gateX = tracks{1,tentTrackCounter}.x - tracks{1,TrackCounter}.xUzunluk; % gate x
                                 tracks{1,TrackCounter}.gateY = tracks{1,tentTrackCounter}.y - tracks{1,TrackCounter}.yUzunluk; % gate y
                                 tracks{1,TrackCounter}.gateXUzunluk = 3*tracks{1,TrackCounter}.xUzunluk; % gate x uzunluk
                                 tracks{1,TrackCounter}.gateYUzunluk = 3*tracks{1,TrackCounter}.yUzunluk; % gate y uzunluk

                                 tracks{1,TrackCounter}.age = tracks{1,TrackCounter}.age + 1;                                                                      
                                 if (tracks{1,TrackCounter}.age < 4)
                                     tracks{1,TrackCounter}.lastThreeTours(tracks{1,TrackCounter}.age) = 1;
                                 else
                                     tracks{1,TrackCounter}.lastThreeTours = [tracks{1,TrackCounter}.lastThreeTours(2:3), 1];
                                 end
                                 rectangle('Position', [GateX, GateY, GateXUzunluk, GateYUzunluk], 'EdgeColor', 'r', 'LineWidth', 2)
                                 pause(0.25)
                                 break;
                                 
                             end
                          end
                      end
                   end
                end 
            end
            %tentative cycle
            if size(tentativeTracks,2) > 0
                for newTentTrackCounter = 1:1:numberOfObjects
                    if availabilityList(newTentTrackCounter) == 1 
                    
                        newDetectionX = stats(newTentTrackCounter).BoundingBox(1); 
                        newDetectionY = stats(newTentTrackCounter).BoundingBox(2);
                        newDetectionXUzunluk = stats(newTentTrackCounter).BoundingBox(3); 
                        newDetectionYUzunluk = stats(newTentTrackCounter).BoundingBox(4); 
                        
                        for tentTrackCounter = 1:1:size(tentativeTracks,2)
                            if tentativeTracks{tentTrackCounter}.isUpdated == 0
                                tentGateX = tentativeTracks{1,tentTrackCounter}.gateX;
                                tentGateY = tentativeTracks{1,tentTrackCounter}.gateY;
                                tentGateXUzunluk = tentativeTracks{1,tentTrackCounter}.gateXUzunluk;
                                tentGateYUzunluk = tentativeTracks{1,tentTrackCounter}.gateYUzunluk;
                                
                                % eger tentative track'in gate'i ile bu
                                % tespitin bounding box'ı kesisiyorsa bu
                                % tespit ile bu tentative track iliskilendirilir. Yani tentative track bu tespit ile update edilir. 
                                isIntersected = 0;
                                % kesisim incelemesi, kesisiyorsa isIntersected = 1;
                                A = [newDetectionX, newDetectionY, newDetectionXUzunluk, newDetectionYUzunluk];
                                B = [tentGateX, tentGateY, tentGateXUzunluk, tentGateYUzunluk];
                                area = rectint(A,B);
                                
                                if area >= 1
                                   isIntersected = 1; 
                                end
                                
                                if isIntersected == 1
                                    tentativeTracks{1,tentTrackCounter}.isUpdated = 1;
                                    availabilityList(newTentTrackCounter) = 0;
                                    
                                    tentativeTracks{1,tentTrackCounter}.xVeloctiy = newDetectionX - tentativeTracks{1,tentTrackCounter}.x; % in pixels
                                    tentativeTracks{1,tentTrackCounter}.yVeloctiy = newDetectionY - tentativeTracks{1,tentTrackCounter}.y;
                                    
                                    tentativeTracks{1,tentTrackCounter}.xUzunluk = newDetectionXUzunluk; %dikdortgenin x uzunlugu;
                                    tentativeTracks{1,tentTrackCounter}.yUzunluk = newDetectionYUzunluk; %dikdortgenin y uzunlugu
                                    tentativeTracks{1,tentTrackCounter}.x = newDetectionX;  % x uzunlugu
                                    tentativeTracks{1,tentTrackCounter}.y = newDetectionY;  % y uzunlugu
                                    % bunu incelemek gerek, ortadan degil, koseden aciyor
                                    % gate i
                                    tentativeTracks{1,tentTrackCounter}.gateX = tentativeTracks{1,tentTrackCounter}.x - tentativeTracks{1,tentTrackCounter}.xUzunluk; % gate x
                                    tentativeTracks{1,tentTrackCounter}.gateY = tentativeTracks{1,tentTrackCounter}.y - tentativeTracks{1,tentTrackCounter}.yUzunluk; % gate y
                                    tentativeTracks{1,tentTrackCounter}.gateXUzunluk = 3*tentativeTracks{1,tentTrackCounter}.xUzunluk; % gate x uzunluk
                                    tentativeTracks{1,tentTrackCounter}.gateYUzunluk = 3*tentativeTracks{1,tentTrackCounter}.yUzunluk; % gate y uzunluk

                                    tentativeTracks{1,tentTrackCounter}.age = tentativeTracks{1,tentTrackCounter}.age + 1;                                                                      
                                    if (tentativeTracks{1,tentTrackCounter}.age < 4)
                                        tentativeTracks{1,tentTrackCounter}.lastThreeTours(tentativeTracks{1,tentTrackCounter}.age) = 1;
                                    else
                                        tentativeTracks{1,tentTrackCounter}.lastThreeTours = [tentativeTracks{1,tentTrackCounter}.lastThreeTours(2:3), 1];
                                    end
                                    rectangle('Position', [tentGateX, tentGateY, tentGateXUzunluk, tentGateYUzunluk], 'EdgeColor', 'r', 'LineWidth', 2)
                                    pause(0.25)
                                    break;
                                end
                            end
                        end
                    end
                end
            end
            
            % isUpdate degiskeninin guncellenmesi
            for tentTrackCounter = 1:1:size(tentativeTracks,2)
                if tentativeTracks{1,tentTrackCounter}.isUpdated == 0
                    if (tentativeTracks{1,tentTrackCounter}.age < 4)
                        tentativeTracks{1,tentTrackCounter}.lastThreeTours(tentativeTracks{1,tentTrackCounter}.age) = 0;
                    else
                        tentativeTracks{1,tentTrackCounter}.lastThreeTours = [tentativeTracks{1,tentTrackCounter}.lastThreeTours(2:3), 0];
                    end
                end
                tentativeTracks{1,tentTrackCounter}.isUpdated = 0;
            end
            
            % tentative to track conversion
            for tentTrackCounter = size(tentativeTracks,2):-1:1
                if (sum(tentativeTracks{1,tentTrackCounter}.lastThreeTours) == 3)
                    tracks{size(tracks,2)+1} = tentativeTracks{1,tentTrackCounter};
                    tentativeTracks(tentTrackCounter) = [];
                end
            end
            
            
            for newTentTrackCounter = 1:1:numberOfObjects
                if availabilityList(newTentTrackCounter) == 1
                    tentativeTracks{1,size(tentativeTracks,2)+1}.xUzunluk = stats(newTentTrackCounter).BoundingBox(3); %dikdortgenin x uzunlugu;
                    tentativeTracks{1,size(tentativeTracks,2)}.yUzunluk = stats(newTentTrackCounter).BoundingBox(4); %dikdortgenin y uzunlugu
                    tentativeTracks{1,size(tentativeTracks,2)}.x = stats(newTentTrackCounter).BoundingBox(1);  % x uzunlugu
                    tentativeTracks{1,size(tentativeTracks,2)}.y = stats(newTentTrackCounter).BoundingBox(2);  % y uzunlugu
 
                    tentativeTracks{1,size(tentativeTracks,2)}.gateX = tentativeTracks{1,size(tentativeTracks,2)}.x - tentativeTracks{1,size(tentativeTracks,2)}.xUzunluk; % gate x
                    tentativeTracks{1,size(tentativeTracks,2)}.gateY = tentativeTracks{1,size(tentativeTracks,2)}.y - tentativeTracks{1,size(tentativeTracks,2)}.yUzunluk; % gate y
                    tentativeTracks{1,size(tentativeTracks,2)}.gateXUzunluk = 3*tentativeTracks{1,size(tentativeTracks,2)}.xUzunluk; % gate x uzunluk
                    tentativeTracks{1,size(tentativeTracks,2)}.gateYUzunluk = 3*tentativeTracks{1,size(tentativeTracks,2)}.yUzunluk; % gate y uzunluk
                    
                    tentativeTracks{1,size(tentativeTracks,2)}.xVeloctiy = 0; % in pixels
                    tentativeTracks{1,size(tentativeTracks,2)}.yVeloctiy = 0;
                    
                    tentativeTracks{1,size(tentativeTracks,2)}.age = 1;
                    tentativeTracks{1,size(tentativeTracks,2)}.lastThreeTours = [1,0,0];%1 updated, 0 not updated yet
                    tentativeTracks{1,size(tentativeTracks,2)}.isUpdated = 0;%1 updated, 0 not updated yet
                    
                    availabilityList(newTentTrackCounter) = 0;
                end
            end
           
            
            %% frameler arasi süre
            frameler_arasi_sure = numOfAveragedFrames*(1/videoObject.FrameRate); %periyot
            
            %%
            previousFrame = frame;
            frame = zeros(videoObject.Height,videoObject.Width,3);
        else
            frame = frame + double(read(videoObject,i));
        end
    end
    
end
