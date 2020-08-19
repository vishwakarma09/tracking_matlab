%% set-up serial port
serial_port = serial('COM4');   %com port 4
fopen(serial_port);             %open port
fprintf(serial_port,'%c','s');
 
tangle = 30;                     %threshhold angle
direction = 0;                   %initial direction
distance_old = 70;               %reference distance
 
%% setup wecam
vid = videoinput('winvideo', 1, 'YUY2_320x240');
src = getselectedsource(vid);
vid.FramesPerTrigger = 1;
vid.ReturnedColorspace = 'rgb';
imaqmem(1000000000);
vid.TriggerRepeat = Inf;
triggerconfig(vid, 'manual');
preview(vid);
start(vid);
 
%% process images
flag=true;
while(flag==true)
    trigger(vid);
    m = getdata(vid);
    imshow(m(:,:,:,1));
 
    % image segmentation
    a = m(:,:,:,1);
    subplot(2,3,1),imshow(a);
    b = rgb2gray(a);
    subplot(2,3,2),imshow(b);
    c = im2bw(a,graythresh(b));
    subplot(2,3,3),imshow(c);
    d = ~ c;
    subplot(2,3,4),imshow(d);
 
    % object detection
    cc = bwconncomp(d, 4);
    s = regionprops(cc, 'Centroid','Orientation');
    subplot(2,3,5),imshow(c);
    hold on
    plot(s(1).Centroid(1), s(1).Centroid(2), '--rs','LineWidth',2,...
                    'MarkerEdgeColor','k',...
                    'MarkerFaceColor','g',...
                    'MarkerSize',10);
    plot(s(2).Centroid(1), s(2).Centroid(2), '--rs','LineWidth',2,...
                    'MarkerEdgeColor','k',...
                    'MarkerFaceColor','g',...
                    'MarkerSize',10);
    hold off
 
    % angle finding
    angle_box = round(s(1).Orientation);        %angle of rect
    angle_pic = round(atan((s(2).Centroid(2) - s(1).Centroid(2))/(s(2).Centroid(1) - s(1).Centroid(1)))*100);
    distance = round(sqrt((s(2).Centroid(2) - s(1).Centroid(2))^2 + (s(2).Centroid(2) - s(1).Centroid(1))^2)); 
 
    % move calculation
    if(distance < 20)
        flag=false;
        break;
    end
    
    if(distance > distance_old)
        direction =~ direction;
    end
    
    if ((angle_box <= angle_pic + tangle) && (angle_box >= angle_pic - tangle))
        fprintf(serial_port,'%c',get_direction_char(direction));
    elseif (angle_box > angle_pic + tangle)
        fprintf(serial_port,'%c','l');           %move right -> 'l'
    else
        fprintf(serial_port,'%c','r');           %move left -> 'r'        
    end
 
    pause(1);
    fprintf(serial_port,'%c','s');
    pause(2);
    
    distance_old = distance;
end
 
 
%% clear webcam object
stoppreview(vid);
stop(vid);
delete(vid);
clear vid;
 
% close com port
fclose(serial_port);
clear serial_port;

%% function to get direction - f or b
function [direction]=get_direction_char(x)
    if(x==0)
        direction = 'f';
    else
        direction = 'b';
    end
end
