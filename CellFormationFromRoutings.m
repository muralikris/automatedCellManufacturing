% Reads Input Excel File and Generates Machine Part Matrix
inputFileName = 'PartRoutings.xlsx';

%% Part Related data
RoutingDataSheet = 1;
[num,txt,rawPartData] = xlsread(inputFileName,RoutingDataSheet);
partNum=rawPartData(:,1);
machineSeqOfOperation=rawPartData(:,2);
totalOperationTime=rawPartData(:,3);
batchQuantity=rawPartData(:,4);
partNum=partNum(2:end);
machineSeqOfOperation=machineSeqOfOperation(2:end);
totalOperationTime = totalOperationTime(2:end);
batchQuantity=batchQuantity(2:end);
partNumMat = cell2mat(partNum);
batchQuantityMat = cell2mat(batchQuantity);
partNums= unique(partNumMat);
assert(numel(partNums) == numel(partNumMat),'Input Part Data Contains Duplicates');

%% Machine Related data
MachineDatasheet = 2;
numMachineData = xlsread(inputFileName,MachineDatasheet);
machineNumMat = numMachineData(:,1);
availableNumEachMachine = numMachineData(:,2);
machineNums= unique(machineNumMat);
machineNums = sort(machineNums);
assert(numel(machineNumMat) == numel(machineNums),'Input Machine Data Contains Duplicates');
% Preprocess and remove station/machine numbers which are not value added
% Eg: Shipping, Receiving etc

%%  Machine Part Matrix Generation
machinePartMat= zeros(numel(partNums),numel(machineNums));
%operationSequences = cellfun(@(str) regexprep(str,',',' '), machineSeqOfOperation, 'UniformOutput', false);

for indM = 1: numel(partNums)
    tmpMachineStr = machineSeqOfOperation{indM};
    
    if isempty(tmpMachineStr)
         continue
    elseif numel(tmpMachineStr)> 1
        tmpMachineStr= regexprep(tmpMachineStr,',',' ');
        tmpMachinemat= str2num(tmpMachineStr);
        machinePartMat(indM,:) = ismember(machineNums,tmpMachinemat)';
    elseif(isfinite(tmpMachineStr))
        machinePartMat(indM,:) = ismember(machineNums,tmpMachineStr)'; 
    else
        continue
    end
end

%% Graph Creation for Machines
machineGraph= zeros(numel(machineNums),numel(machineNums));
for indP = 1: numel(partNums)
    tmpRoutingStr = machineSeqOfOperation{indP};
    tmpRoutingMat = [];

    if numel(tmpRoutingStr)> 1
        tmpRoutingStr= regexprep(tmpRoutingStr,',',' ');
        tmpRoutingMat= str2num(tmpRoutingStr);
    elseif(isfinite(tmpRoutingStr))
        tmpRoutingMat = tmpRoutingStr; 
    end
    
    if ~isempty(tmpRoutingMat) && numel(tmpRoutingMat)>1
        graphRowInd=tmpRoutingMat(1);
        for indR = 2: numel(tmpRoutingMat)
            graphColInd=tmpRoutingMat(indR);
            machineGraph(graphRowInd,graphColInd)= machineGraph(graphRowInd,graphColInd)+1;
            graphRowInd= graphColInd;
        end
    end
end

%% Cell formatio from Machine Graph
cellsWithMachines = getCellsFromRoutings (machineGraph);