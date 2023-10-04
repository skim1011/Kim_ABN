% calcuate single place field from ratemap

vel_all = vel_filt_rmap;
mazenum = 5;   % number of sessions
cellnum = 210; % number of cells

field_size_all = { }; 
single_field_all = { }; 
single_rate_all = { };
out_of_field_rate_all = NaN(cellnum, mazenum);
No_field_all = NaN(cellnum, mazenum);
out_of_field = { };

for current_cell = 1:cellnum
    for current_maze = 1:mazenum
    
      try
       
    if ~isempty(vel_all{current_cell, current_maze})
        
        Rmap = vel_all{current_cell,current_maze};
             
            peakrate = max(max(Rmap));
            single_fields = cell(10,1);
            single_rate = cell(10,1);
            A1 = Rmap;
            A2 = A1;
            A2(find(isnan(A1))) = 0;
            alpha = .2;
            pos1 = A2< (alpha*peakrate);
            A2(pos1) = 0;
            Not_field_count = 0;
            Num_Fields = 0;
            [L1, NUM] = bwlabeln(A2, 4);
            contiguous_pixels_count = 30; 
            if (NUM>=1)
                for index2 = 1:NUM
                    pos3 = L1==index2;
                    contiguous_pixels = sum(sum(pos3));
                    if (contiguous_pixels < contiguous_pixels_count)
                        Not_field_count = Not_field_count + 1;
                        Not_Field(Not_field_count,1) = index2;
                        L1(pos3)=0;
                        A2(pos3) = 0;

                    else
                        Num_Fields = Num_Fields + 1;
                        pos4 = L1~=index2;
                        pos3 = L1==index2; 
                        A3 = A1;
                        A5 = A1; 
                        A5(pos4) = 0;
                        A3(pos4) = NaN; 
                        A1(pos3) = NaN; 
                        single_fields{Num_Fields} = A3;
                        field_size_pixels{Num_Fields} = contiguous_pixels;
                        single_rate{Num_Fields} = nanmean(nanmean(A3));
                        clear A3 A5;
                    end
                    clear pos3 contiguous_pixels
                end
                clear index2
            end
            out_of_field_rate = nanmean(nanmean(A1));
                
    single_field_all{current_cell,current_maze} = single_fields;
    field_size_all{current_cell,current_maze} = field_size_pixels;
    single_rate_all{current_cell,current_maze} = single_rate;
    out_of_field_all{current_cell, current_maze} = A1;
    out_of_field_rate_all(current_cell,current_maze) = out_of_field_rate;
    No_field_all(current_cell,current_maze) = Num_Fields;
    
    clear single_fields;
    clear field_size_pixels;
    clear single_rate;   
    clear out_of_field_rate;
    clear Num_Fields;
    clear A1;
    end
      catch
          continue
      end
    end
    
end
