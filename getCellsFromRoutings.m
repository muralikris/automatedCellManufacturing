function cellsConfiguration = getCellsFromRoutings (routingsMat)

cellsConfiguration = {};
if isempty(routingsMat)
    return
end
cellsWithMachines= {};
numMachineInEachCell = [];
cellsTypeOfStop= []; %1: Dead-end, 2: Loop, 3: Fork

% while atleast one cells in Routings Graph is non-zero
tmpMachineGraph = routingsMat;
for numIteration =1 : size(routingsMat,1)
    maxValuesPerColumn= max (tmpMachineGraph);
    maxValueInGraph = max(maxValuesPerColumn);
    
    if maxValueInGraph >0
        maxValueColumnInd= find(maxValuesPerColumn==maxValueInGraph);
        
        rowColPairs = [];
        for colInd= 1: numel(maxValueColumnInd)
            tmpColumn = tmpMachineGraph(:,maxValueColumnInd(colInd));
            maxValueRowInd = find(tmpColumn == maxValueInGraph);
            repCols= repmat(maxValueColumnInd(colInd), numel(maxValueRowInd),1);
            tmpRowCols= [maxValueRowInd repCols];
            rowColPairs= [rowColPairs;tmpRowCols];
        end
        
        for cellInd= 1: size(rowColPairs,1)
            tmpRowCols= rowColPairs(cellInd,:);
            tmpMachineGraph(tmpRowCols(1),tmpRowCols(2))= 0;
            
            % Go to routings for the last visited machine
            tmpInd = numel(tmpRowCols); 
            tmpRow = tmpMachineGraph(tmpRowCols(tmpInd),:);
            maxValueNextRouting = max(tmpRow); 
            routingEnd =1 ;
            while maxValueNextRouting > 0
                tmpMachineInd = find(tmpRow == maxValueNextRouting);
                bLoopPresent = ismember(tmpMachineInd,tmpRowCols);
                
                if any(bLoopPresent)
                    loopingMachineInd = tmpMachineInd(bLoopPresent);
                    tmpMachineGraph(tmpRowCols(tmpInd),loopingMachineInd)= 0;
                    
                    tmpRowCols = [tmpRowCols loopingMachineInd];
                    maxValueNextRouting = 0;
                    routingEnd =2 ;
                elseif numel(tmpMachineInd)== 1  
                    tmpMachineGraph(tmpRowCols(tmpInd),tmpMachineInd)= 0;
                    
                    tmpRowCols = [tmpRowCols tmpMachineInd];
                    tmpInd = numel(tmpRowCols);
                    tmpRow = tmpMachineGraph(tmpRowCols(tmpInd),:);
                    maxValueNextRouting = max(tmpRow);  
                    routingEnd =1 ;
                else
                    tmpMachineGraph(tmpRowCols(tmpInd),tmpMachineInd)= 0;
                    tmpRowCols = [tmpRowCols tmpMachineInd];
                    maxValueNextRouting = 0;   
                    routingEnd =3 ;
                end
            end
            
            % Fill the cells array
            cellsWithMachines = [cellsWithMachines; tmpRowCols];
            cellsTypeOfStop = [cellsTypeOfStop; routingEnd];
            uniqueMachine= unique(tmpRowCols);
            numMachineInEachCell = [numMachineInEachCell; numel(uniqueMachine)];
        end
    else
        break
    end
end

[numMachineInEachCell, sortedInd] = sort(numMachineInEachCell,'descend');
cellsWithMachines = cellsWithMachines(sortedInd);
cellsTypeOfStop = cellsTypeOfStop(sortedInd);

deadEndCellsInd= (cellsTypeOfStop ==1);
deadEndCells = cellsWithMachines (deadEndCellsInd);

loopCellsInd= (cellsTypeOfStop ==2 );
loopCells = cellsWithMachines (loopCellsInd);

forkCellsInd= (cellsTypeOfStop == 3 );
forkCells = cellsWithMachines (forkCellsInd);

% Group the cells which have same ending machine
endingMachine=zeros(size(deadEndCells));
for deadCellInd= 1: numel(deadEndCells)
    tmpCell= deadEndCells{deadCellInd};
    endingMachine(deadCellInd)= tmpCell(end);
end

uniqueEndMachines= unique(endingMachine);
superCells={};
usedMachineList=[];
for endMachInd= 1: numel(uniqueEndMachines)
    superCellInd= ismember(endingMachine,uniqueEndMachines(endMachInd));
    tmpMachInCell= deadEndCells(superCellInd);
    if numel(tmpMachInCell)>1
        tmpMachines=[];
        for subCellInd= 1: numel(tmpMachInCell)
            tmpMachines=[tmpMachines, tmpMachInCell{subCellInd}];
        end
        tmpMachines= unique(tmpMachines);
        superCells = [superCells; tmpMachines];
        usedMachineList =[usedMachineList,tmpMachines];
    else
       superCells = [superCells; tmpMachInCell{1}];
       usedMachineList =[usedMachineList,tmpMachInCell{1}];
    end
end

% Combine Sub-sets
tmpCells= superCells;
for combInd= 1: numel(superCells)
    if combInd < numel(tmpCells)
        currentSet=tmpCells{combInd};        
        remainingSet= tmpCells(combInd+1:end); 
        remainingInd= combInd+1:numel(tmpCells);
        
        eliminateInd =[];
        for remainInd= 1: numel(remainingSet)
            tmpSet=remainingSet{remainInd};
            isSubSet= ismember(tmpSet,currentSet);
            if all(isSubSet)
                eliminateInd =[eliminateInd; remainingInd(remainInd)];
            end                
        end
        if ~isempty(eliminateInd)
            tmpCells(eliminateInd)=[];
        end
    end
end

cellsConfiguration = tmpCells;
usedMachineList = unique(usedMachineList);
allMachineList= 1:size(routingsMat,1);
usedMachineInd= ismember(allMachineList,usedMachineList);
unusedMachines= allMachineList(~usedMachineInd);

% Are there any machines not part of the deadEndCells? 
if isempty(unusedMachines)
    return
else % start processing loopCells
    for indLoop = 1:numel(loopCells)
        if isempty(unusedMachines)
            break
        end
        
        tmpLoopRouting= loopCells{indLoop};                
        machineUsedInLoop = ismember(unusedMachines,tmpLoopRouting);
        if any(machineUsedInLoop)
            %Find home cell for tmpLoopRouting
            cellsConfiguration = matchIncomingRoutingToCell(cellsConfiguration,tmpLoopRouting,unusedMachines);
            unusedMachines= unusedMachines(~machineUsedInLoop);
        end
    end
end

if isempty(unusedMachines)
    return
else % start processing forkCells
    for indFork = 1:numel(forkCells)
        if isempty(unusedMachines)
            break
        end
        tmpForkRouting= forkCells{indFork};                
        machineUsedInFork = ismember(unusedMachines,tmpForkRouting);
        if any(machineUsedInFork)
            %Find home cell for tmpForkRouting
            cellsConfiguration = matchIncomingRoutingToCell(cellsConfiguration,tmpForkRouting,unusedMachines);
            unusedMachines= unusedMachines(~machineUsedInFork);
        end
    end    
end

end

function updatedCells = matchIncomingRoutingToCell (existingCells,incomingRouting,unusedMachines)

if isempty(existingCells)|| isempty (incomingRouting) || isempty(unusedMachines)
    updatedCells ={};
    return
else
    updatedCells= existingCells;
end

matchScore= zeros(size(existingCells));
unusedMachinesInd = ismember(incomingRouting,unusedMachines);
existingMachinesCount= sum(~unusedMachinesInd);
unusedMachinesCount =  sum(unusedMachinesInd);

for existingCellInd= 1: numel(existingCells)
    tmpCellRouting= existingCells{existingCellInd};
    matchedInd= ismember(tmpCellRouting,incomingRouting);
    matchScore(existingCellInd)= sum(matchedInd);
end

[maxMatchScore, maxInd] = max(matchScore);
tmpRouting = existingCells{maxInd};
mergedRouting= [tmpRouting,incomingRouting];
mergedRouting= unique(mergedRouting);
updatedCells{maxInd}= mergedRouting;
end