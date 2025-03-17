
registeredImageStruct = nii_tool('load', 'Risultati/movingRegistered.nii.gz');
registeredImage = double(registeredImageStruct.img);
sliceViewer(registeredImage);

% registeredImageStruct = nii_tool('load', 'Risultati/movingRegistered.nii.gz');
% registeredImage = double(registeredImageStruct.img);
% sliceViewer(registeredImage);