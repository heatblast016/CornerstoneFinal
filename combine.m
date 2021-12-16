function [combined] = combine(base,layer)
%Combines two images by overlaying nonzero pixels
%Goes through and checks which pixels in the "layer" have color, and
%replaces pixels in the "base" with those
    combined = base;
    [sizew, sizel, sizez] = size(base);
    for i = 1:sizew
        for j = 1:sizel
            if (layer(i,j,1) ~= 0)
                combined(i,j,:) = layer(i,j,:);
            end
        end
    end

end