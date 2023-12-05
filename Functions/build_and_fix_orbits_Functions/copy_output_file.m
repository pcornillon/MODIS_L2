function copy_output_file( input_filename, output_filename)
% copy_output_file - from one storage location to another - PCC 
%   
% This function is meant to be submitted as a batch job from the function
% Write_SST_File in MODIS_L2. The resulting job will simply copy
% input_filename to output_filename. The idea is that the input file is the
% file that was just written by Write_SST_File to local storage and the
% output file is the same file but written to an NFS mounted storage
% device. Writing the file to the local storage will be fast--writing the
% same file to a remote NFS device can be agonizingly slow. Copying the
% file will be faster. Submitting the copy function as a batch job means
% that build_and_fix_orbits can move to processing the next orbut as this
% job copies it. This job will also delete the file from local storage when
% done. 
%
% INPUT
%   input_filename - the fully specified file to be copied; by fully
%    specified, means with current location of the file.
%   output_filename - the same filename but with the NFS output location.
%
% OUTPUT
%   None
%

status = 0;

% Copy the file using rsync

eval(['! rsync -av ' input_filename ' ' output_filename])

% Make sure that the file copied properly.

output_details = dir(output_filename);
input_details = dir(input_filename);

if (output_details.bytes == input_details.bytes) & (output_details.bytes > 10^8)
    eval(['! rm ' input_filename])
else
    status = 1;
end

end