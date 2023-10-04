% to calcuate spatial correlation values between mazes
X = vel_filt_rmap;
Num_of_Units = 166;
i = Num_of_Units;
std = NaN(i,1);
mis = NaN(i,1);

for unit = 1: i
    try
    if active_session(unit,1)==1 | active_session(unit,3)==1  
        A = corrcoef(X{unit,1}, X{unit,3},'rows','complete');
        std(unit) = A(1,2);
    end
    catch
        std(unit) = NaN;
    continue
    end
    
    
end

for unit = 1: i
       
    try
    if active_session(unit,1)==1 | active_session(unit,2)==1  
        B = corrcoef(X{unit,1}, X{unit,2},'rows','complete');
        mis(unit) = B(1,2);
    end
    catch
        mis(unit) = NaN;
        continue
    end
    
end
