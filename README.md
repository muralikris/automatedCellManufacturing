# automatedCellManufacturing
This is a matlab script which takes product routings as input to produce manufacturing cells
Step1: Convert Routing Sheet into a Machine Graph Matrix
Step2: Iteratively start to form Cells using Machine Graph Matrix until all values in the matrix are 0
.Get the most frequent routing pairs 
. For all the routing pairs, utilizing the ending machine, continue the routing flow by performing the search using them as starting machine until it leads to a dead-end (Row with all zeros). 
. Loops are not allowed. So end the search when search hits dead-end or forms a loop.
.	End the search, when search results in path leading to fork (2 or more search paths).
Step 3: Perform post processing on cells from Step 2
. For cells which ended with dead-end have natural ending. So, they will have first priority for forming machine cells.
. Group the cells which have same ending machine
. Then combine any Sub-set Cells
•	Are there still machines not part of the above dead-end Cells? 
. Yes:  
  . Use cells derived from loops (1), followed by forks (2) to cover the unused machines.
  .Based on number of common machines, either merge the cells into existing dead-end cells or create a new cell.
.No:
  .End the cell formation process


