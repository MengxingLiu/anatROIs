% Y=inpaint(X,M): Inpaints X(M) with values of closest voxels
function Y=inpaint(X,M)

Y=X;
[BW,nlab]=bwlabeln(M,6);
for n=1:nlab
    [~,cropping]=cropLabelVol(BW==n,1);
    Mcrop=applyCropping(M,cropping);
    Xcrop=applyCropping(X,cropping);
    Ycrop=applyCropping(Y,cropping);
    
    label_list=unique(Xcrop(~Mcrop));
    D=zeros([size(Xcrop) length(label_list)]);
    for l=1:length(label_list)
        D(:,:,:,l)=bwdist(Xcrop==label_list(l)); % maybe I should add  ->  & Mcrop==0
    end
    [~,ind]=min(D,[],4);
    S=label_list(ind);
    Ycrop(Mcrop)=S(Mcrop);
    Y(cropping(1):cropping(4),cropping(2):cropping(5),cropping(3):cropping(6))=Ycrop;
end




