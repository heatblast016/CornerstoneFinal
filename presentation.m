clear
%configures pins and initializes servos
ard = arduino('COM7', 'Uno',  'Libraries','Ultrasonic','Libraries','Servo');

configurePin(ard, 'D2', 'pullup');
configurePin(ard, 'D3', 'pullup');
configurePin(ard, 'D4', 'pullup');
configurePin(ard, 'D11', 'PWM');
configurePin(ard, 'D10', 'PWM');
configurePin(ard, 'D9', 'PWM');
servo1 = servo(ard, 'D11');
servo2 = servo(ard, 'D10');
servo3 = servo(ard, 'D9');
%Pulls servos in
writePosition(servo1, 0.5);
writePosition(servo2, 0.5);
writePosition(servo3, 0.5);
globdelay = 0.25;

%initializes webcam
cam = webcam(2);
cam.Resolution='1280x720';
preview(cam)
%initializes window with dimensions spanning the whole screen
figure('units','normalized','outerposition',[0 0 1 1])
answerlog = [];
for i = 1:32
    %loads each slide on button press
    clear sound;
    name = int2str(i);
    answer = false;
    %gets slide photo and audio file names
    file = strcat(name, ".png");
    audio = strcat(name, ".mp3");
    if(isfile(audio))
        %reads audio
        [y, Fs] = audioread(audio);
        sound(y, Fs, 16);
    end
    [img, map] = imread(file);
    %displays slide
    imshow(img,map, 'InitialMagnification','fit');
    while true
        %wait for arduino input
        x = getButtons(ard);
        if (i == 17 || i == 12 || i == 32) && answer == false
            %if slides are question slides, switches to the selected answer,
            %lets the program know that current slide is an "answer" slide
            if(x == 1)
                clear sound;
                imshow(strcat("a", file), 'InitialMagnification','fit')
                audio = strcat(strcat("a", audio));
                if(isfile(audio))
                    [y, Fs] = audioread(audio);
                    sound(y, Fs, 16);
                end
                answer = true;
                answerlog(length(answerlog) + 1) = 1; 
                pause(globdelay)
            elseif(x == 2)
                clear sound;
                imshow(strcat("b", file), 'InitialMagnification','fit')
                audio = strcat(strcat("b", audio));
                if(isfile(audio))
                    [y, Fs] = audioread(audio);
                    sound(y, Fs, 16);
                end
                answer = true;              
                answerlog(length(answerlog) + 1) = 2;
                pause(globdelay)
            elseif(x==3)
                clear sound;
                imshow(strcat("c", file), 'InitialMagnification','fit')
                answer = true;
                audio = strcat(strcat("c", audio));
                if(isfile(audio))
                    [y, Fs] = audioread(audio);
                    sound(y, Fs, 16);
                end
                answerlog(length(answerlog) + 1) = 3;

                pause(globdelay)
            end
        else
            if(x ~= 0)
                answer = false;
                pause(globdelay)
                break
            end
        end 

    end
end



% results code -- gets tracked answers and checks to see proportion that
% are correct, then loads a custom results screen based on the answers
resultfile = strcat(int2str((answerlog(1)==3)),int2str((answerlog(2)==2)),int2str((answerlog(3)==3)),"results.png");
[img, map] = imread(resultfile);
imshow(img,map, 'InitialMagnification','fit');
clear sound;
while true
    x = getButtons(ard);
    if(x ~= 0)
        answer = false;
        pause(globdelay)
        break
    end
end

%loads fire lines presentation
for i = 33:36
    %loads each slide and sound for the slide
    clear sound;
    name = int2str(i);
    answer = false;
    file = strcat(name, ".png");
    audio = strcat(name, ".mp3");
    if(isfile(audio))
        [y, Fs] = audioread(audio);
        %plays sound
        sound(y, Fs, 16);
    end
    [img, map] = imread(file);
    %shows slide in window
    imshow(img,map, 'InitialMagnification','fit');
    while true
        %wait for arduino input
        x = getButtons(ard);
        if(x ~= 0)

            pause(globdelay)
            break
        end
    end 

end
%start simulation 
%extend servos out
writePosition(servo1, 0);
writePosition(servo2, 0);
writePosition(servo3, 0);

% loads slide with fireline templates
[img, map] = imread("map.png");
imshow(img,map,'InitialMagnification','fit');
while true
    x = getButtons(ard);
    if(x ~= 0)
        answer = false;
        break
    end
end


[oops, oop] = imread("oops.png");
[transition, throwaway] = imread("2.png");
%reads blocks
notread = true;
while notread
    %reads frame, converts to grayscale and then sharpens (sharpening step
    %is optional, depending on camera quality)
    frame = snapshot(cam);
    frame = rgb2gray(frame);
    frame = imsharpen(frame);
    %splits image into 3 parts, for each block
    A = imcrop(frame,[1 1 400 720]);
    B = imcrop(frame,[427 1 400 720]);
    C = imcrop(frame,[850 1 429 720]);
    %reads qr code from each block, parses out any whitespace
    line1 = strtrim(readBarcode(A))
    line2 = strtrim(readBarcode(B))
    line3 = strtrim(readBarcode(C))
    pause(globdelay)
    
    %checks if any of the blocks weren't read, loads error slide if so
    if (line1 == "" || line2 == "" || line3 == "")
        imshow(oops,oop, 'InitialMagnification','fit')
        while true
            x = getButtons(ard);
            if(x == 1)
                line1="1";
                line2 = "2";
                line3 = "3";
                notread = false;

                pause(globdelay)
                break;
            elseif(x ~= 0)
                imshow(transition, throwaway, 'InitialMagnification','fit')
                pause(0.5)
                break;
            end
        end

    else
        notread = false;
    end
end
%gets base map, adds overlays based on firelines that were chosen
[basemap, map] = imread("base.png");
[overlay, dummy] = imread(line1+"layer.png");
[overlay2, dummy2] = imread(line2+"layer.png");
[overlay3, dummy3] = imread(line3+"layer.png");
combined = combine(basemap,overlay); 
combined = combine(combined,overlay2);
combined = combine(combined,overlay3);
seedx = 225;
seedy = 225;

%resizes map data for performance on slower computers
firemap = imresize(combined,0.15);
%gets map dimensions
[sizew, sizel, sizez] = size(firemap);

%initializes array to keep track of visited points
visited = zeros(sizew, sizel);
visited(seedx,seedy) = 1

%initializes queue to keep track of nodes that need to be processed
qx = Queue;
qy = Queue;
gq = Queue;
qx.enqueue(seedx)
qy.enqueue(seedy)
gq.enqueue(0)
prevgen = 0;
%random array for noise
r2 = randi(3,sizew,sizel);
while ~isempty(qx)        
        %Get next pixel from queue, make it red
        x = dequeue(qx).data;
        y = dequeue(qy).data;
        firemap(x,y,1) = 255;
        %gets distance to explore outwards -- this simulates the fire
        %"jumping" out unpredictably
        dist = r2(x,y); 
        gen = dequeue(gq).data;
        %explore pixel's neighbors, if neighbors aren't visited and are
        %"flammable" then add them to the queue to process
        topcondition = y-dist >= 1;
        bottomcondition = y+dist <= sizel;
        leftcondition = x -dist>= 1;
        rightcondition = x+dist <= sizew;
        %checking pixel neighbors
        if(topcondition && visited(x,y-dist) ==0 && firemap(x,y-dist,2) ==129 )
            visited(x, y-dist) = 1;
            enqueue(qx,x);
            enqueue(qy, y-dist);
            enqueue(gq, gen+1);
        end         
        if(bottomcondition && visited(x,y+dist) ==0 && firemap(x,y+dist,2) ==129 )
            visited(x, y+dist) = 1;
            enqueue(qx,x);
            enqueue(qy, y+dist);

            enqueue(gq, gen+1);
        end         
        if(leftcondition && visited(x-dist,y) ==0&& firemap(x-dist,y,2) ==129 )
            visited(x-dist, y) = 1;
            enqueue(qx,x-dist);
            enqueue(qy, y);
            enqueue(gq, gen+1);
        end
        if(rightcondition  && visited(x+dist,y) ==0&& firemap(x+dist,y,2) == 129 )
            visited(x+dist, y) = 1;
            enqueue(qx,x+dist);
            enqueue(qy, y);
            enqueue(gq, gen+1);
        end 
        %shows the firemap every "step" outwards
        if(gen > prevgen)
            imshow(firemap)
        end
        prevgen = gen;
end

pause(10)
%reloads script
presentation;
