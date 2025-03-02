function fixAllSegmentations(SUBJECT_DIR)
% for each label, we will kill (inpaint) islands whose volume is less than
% this fraction of the largest connected component for that label. I am
% using 0.1 (i.e., 10%)
FRAC = [0.6 0.8 0.9 0.99];  

% Please modify this path so it points to the matlab path of your 
% FreeSurfer installation

%%%%%%%%%%%%
% Don't touch antying from here on
%%%%%%%%%%%%
FREESURFER_HOME=getenv('FREESURFER_HOME')
LUTFILE=sprintf('%s/FreeSurferColorLUT.txt', FREESURFER_HOME)

% Read LookupTable
lut=readtable(LUTFILE,'ReadVariableNames',false,...
    'Delimiter',' ', 'CommentStyle', '#', ...
    'Format', '%f%s%f%f%f%f', 'MultipleDelimsAsOne', 1);

for p=1:length(FRAC)

	segfile=[SUBJECT_DIR '/mri/ThalamicNuclei.v13.T1.mgz'];

	if exist(segfile,'file')

		disp(['Working on ' SUBJECT_DIR]);

		% read segmentation
		mri=MRIread(segfile);
		voxsiz=prod(mri.volres);
		S=mri.vol;

		% unique list of labels
		llist=unique(S(S>0));

		% find those islands to kill
		Misland=zeros(size(S));
		for l=1:length(llist)
			lab=llist(l);
			[BW,nc] = bwlabeln(S==lab,26);
			if nc>1
				h=hist(BW(BW>0),1:nc);
				vols=h*voxsiz;
				for n=1:nc
					if vols(n) < max(vols) * FRAC(p)
						Misland=Misland | BW==n;
    				end
				end
			end
		end

		% inpaint the islands
		S2=inpaint(S,Misland);

		% write to disk
		mri2=mri;
		mri2.vol=S2;
		MRIwrite(mri2,[SUBJECT_DIR '/mri/ThalamicNuclei.v13.T1.FSvoxelSpace.fixed_FRAC_' num2str(FRAC(p)) '.nii.gz']);
	
        % compute volumes
        llist2=unique(S2(S2>0));
        volumes=zeros(length(llist2),2);
        volumes(:,1)=llist2;
        fid=fopen([SUBJECT_DIR '/mri/ThalamicNuclei.v13.T1.fixed_FRAC_' num2str(FRAC(p)) '.volumes.txt'],'w');
        for k=1:length(llist2)
            lab2=llist2(k);
            nuc_name=lut.Var2(lut.Var1==lab2);
            [BW, nc] = bwlabeln(S2==lab2,26);
            h2=hist(BW(BW>0),1:nc);
            volumes(k,2)=sum(h2*voxsiz);
            fprintf(fid,'%s ',nuc_name{:});
            fprintf(fid,'%f\n',volumes(k,2));                
        end
            
        fprintf(fid,'Left-Whole_thalamus %f\n',...
            sum(volumes(ismember(volumes(:,1),...
            lut.Var1(~cellfun('isempty',strfind(lut.Var2,'Left')))),2)));

        fprintf(fid,'Right-Whole_thalamus %f\n',...
            sum(volumes(ismember(volumes(:,1),...
            lut.Var1(~cellfun('isempty',strfind(lut.Var2,'Right')))),2)));
            
        fclose(fid);
    end

end
disp('All done');

