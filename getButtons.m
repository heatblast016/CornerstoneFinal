function pressedbutton = getButtons(ard)
%Gets button inputs from an arduino and returns whichever button is pressed
%If multiple are pressed, biases towards rightmost one
%If none are pressed, returns 0
    if(readDigitalPin(ard,'D2') == 0)
        pressedbutton = 1;
    elseif(readDigitalPin (ard,'D3') == 0)
        pressedbutton = 2;
    elseif(readDigitalPin(ard,'D4') == 0)
        pressedbutton = 3;
    else
        pressedbutton = 0;
    end
end