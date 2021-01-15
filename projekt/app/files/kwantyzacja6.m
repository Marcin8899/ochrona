function [B] = kwantyzacja6(block_struct)

global suma_zer;
mask = [1 1 1 0 0 0 0 0;
        1 1 0 0 0 0 0 0;
        1 0 0 0 0 0 0 0;
        0 0 0 0 0 0 0 0;
        0 0 0 0 0 0 0 0;
        0 0 0 0 0 0 0 0;
        0 0 0 0 0 0 0 0;
        0 0 0 0 0 0 0 0];
    
    B = (block_struct.data) .* mask;
    
    zer=sum(sum(mask(:,:)==0));
    
    suma_zer = suma_zer + zer;
end