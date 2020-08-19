%% set-up serial port
serial_port = serial(&#39;COM4&#39;); %com port 4
fopen(serial_port); %open port
fprintf(serial_port,&#39;%c&#39;,&#39;s&#39;);
tangle = 30; %threshhold angle
direction = 0; %initial direction
distance_old = 70; %reference distance
%% setup wecam
vid = videoinput(&#39;winvideo&#39;, 1, &#39;YUY2_320x240&#39;);
src = getselectedsource(vid);
vid.FramesPerTrigger = 1;
vid.ReturnedColorspace = &#39;rgb&#39;;
imaqmem(1000000000);
vid.TriggerRepeat = Inf;
triggerconfig(vid, &#39;manual&#39;);
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
s = regionprops(cc, &#39;Centroid&#39;,&#39;Orientation&#39;);
subplot(2,3,5),imshow(c);
hold on
plot(s(1).Centroid(1), s(1).Centroid(2), &#39;--rs&#39;,&#39;LineWidth&#39;,2,...
&#39;MarkerEdgeColor&#39;,&#39;k&#39;,...
&#39;MarkerFaceColor&#39;,&#39;g&#39;,...
&#39;MarkerSize&#39;,10);
plot(s(2).Centroid(1), s(2).Centroid(2), &#39;--rs&#39;,&#39;LineWidth&#39;,2,...
&#39;MarkerEdgeColor&#39;,&#39;k&#39;,...
&#39;MarkerFaceColor&#39;,&#39;g&#39;,...
&#39;MarkerSize&#39;,10);
hold off
% angle finding
angle_box = round(s(1).Orientation); %angle of rect
angle_pic = round(atan((s(2).Centroid(2) -
s(1).Centroid(2))/(s(2).Centroid(1) - s(1).Centroid(1)))*100);

distance = round(sqrt((s(2).Centroid(2) - s(1).Centroid(2))^2 +
(s(2).Centroid(2) - s(1).Centroid(1))^2));
% move calculation
if(distance &lt; 20)
flag=false;
break;
end
if(distance &gt; distance_old)
direction =~ direction;
end
if ((angle_box &lt;= angle_pic + tangle) &amp;&amp; (angle_box &gt;= angle_pic -
tangle))
fprintf(serial_port,&#39;%c&#39;,get_direction_char(direction));
elseif (angle_box &gt; angle_pic + tangle)
fprintf(serial_port,&#39;%c&#39;,&#39;l&#39;); %move right -&gt; &#39;l&#39;
else
fprintf(serial_port,&#39;%c&#39;,&#39;r&#39;); %move left -&gt; &#39;r&#39;
end
pause(1);
fprintf(serial_port,&#39;%c&#39;,&#39;s&#39;);
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
