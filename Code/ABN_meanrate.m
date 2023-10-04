X = meanrate; 
for current_cell = 1:456

 if    nlight(current_cell,1)==1 | nlight(current_cell,1)==2
     try
     value = X(current_cell,:)
     MPG(current_cell,1) = nanmean(value);
     clear value max_value;
     catch
         continue
     end
 elseif nlight(current_cell,1)==3 | nlight(current_cell,1)== 4
     try
     value = X(current_cell,:)
     MPG(current_cell,2) = nanmean(value);
     clear value max_value;
     catch
         continue
     end
 elseif nlight(current_cell,1)==5 | nlight(current_cell,1)== 6
     try
     value = X(current_cell,:)
     MPG(current_cell,3) = nanmean(value);
     clear value max_value; 
     catch
         continue
     end
 elseif nlight(current_cell,1)==7 | nlight(current_cell,1)== 8
     try
     value = X(current_cell,:)
     MPG(current_cell,4) = nanmean(value);
     clear value max_value;
     catch
         continue
     end
 elseif nlight(current_cell,1)==9 
     try
     value = X(current_cell,:)
     MPG(current_cell,5) = nanmean(value);  
     clear value max_value;
     catch
         continue
     end
 elseif nlight(current_cell,1)==10 | nlight(current_cell,1)== 11
     try 
     value = X(current_cell,:)
     MPG(current_cell,6) = nanmean(value);  
     clear value max_value;
     catch
         continue
     end
 elseif nlight(current_cell,1)==0 
     
     if cl_all(current_cell,1) == 1% for gc 
     try  
     value = X(current_cell,:)
     MPG(current_cell,7) = nanmean(value);  
     clear value max_value;
     catch
         continue
     end
     
     elseif cl_all(current_cell,1) == 0% for mc  
     try  
     value = X(current_cell,:)
     MPG(current_cell,8) = nanmean(value);  
     clear value max_value;
     catch
         continue
       end
     end     
 else        
 end              
 end


