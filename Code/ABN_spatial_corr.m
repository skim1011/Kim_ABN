X = vel_filt_rmap;
corr_ov = NaN(456,14); 
for current_cell = 1:456
          for i = 1:3
            for j = i+1:4
              if active_session(current_cell,i)==1 | active_session(current_cell,j)==1
             
              a = X{current_cell,i};
              b = X{current_cell,j};
              no = i*j;
              try
               C =  corrcoef(a,b,'rows', 'complete');
               corr_ov(current_cell,no) = C(1,2);
              catch
                  continue
              end
             clear a b no C;
              end     
              end
            end
end