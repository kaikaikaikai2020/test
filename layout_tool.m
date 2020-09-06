classdef layout_tool < handle
    properties
        ini_pos=get(0, 'MonitorPositions');
    end
    
    methods
        function H_out = create_para_panel(obj,paras,mod_sel)
            if nargin < 3
                mod_sel = 1;
            end
            para_num = length(paras);
            fz = 12;
            default_para_num = 2;
            %paras = cell(para_num,1);

            sub_para_num = zeros(para_num,1);
            for i = 1:sub_para_num
                sub_para_num(i) = size(paras{i}{1,2},1);
            end

            h_val = 50;
            h_val2 =40;

            H = 0;
            for i = 1:length(sub_para_num)
                H = H + default_para_num*h_val;
            end
            sub_pos = obj.get_center_pos(obj.ini_pos,[250,H+h_val2]);
            h = figure('unit','pixels','position',sub_pos,'menu','none','toolbar','none',...
                            'Numbertitle','off','Name','设置参数','visible','off','resize','off');
            %movegui(h,'center');
            sub_pane_obj2 = obj.create_vertical_panel(h,[1,1],[H,h_val2]);

            pos_re = get_average_divide_pos_vertical(obj,sub_pane_obj2(1),(h_val-2)*default_para_num,para_num);

            tempobj = [];
            for i = 1:para_num
                sub_info = paras{i};
                panel_obj_para1 = obj.create_panel(sub_pane_obj2(1),pos_re(i,:));
                set(panel_obj_para1,'Title',sub_info{1,1});

                para_name = sub_info{1,2}(:,1);
                para_vals = sub_info{1,2}(:,2);
                sub_pane_obj_cwt = obj.create_vertical_panel_manul(panel_obj_para1,[1,1],27,2);

                for j = 1:length(para_name)
                    sub_sub_info = sub_info{1,2};
                    pos_re2 = get_average_divide_pos_horizontal(obj,sub_pane_obj_cwt(j),(h_val-2)*default_para_num,default_para_num);
                    obj.create_static_text(sub_pane_obj_cwt(j),sub_sub_info{j,1},pos_re2(1,:),fz);
                    str_obj2_c1 = obj.create_popupmenu(sub_pane_obj_cwt(j),sub_sub_info{j,2},pos_re2(2,:),fz);   
                    tempobj = cat(1,tempobj,str_obj2_c1);
                end
            end
            if eq(mod_sel,2)
                pos_re4 = get_average_divide_pos_horizontal(obj,sub_pane_obj2(end),80,2,6);
                str_obj7 = obj.create_button(sub_pane_obj2(end),'确定',pos_re4(1,:),12);
                str_obj8 = obj.create_button(sub_pane_obj2(end),'取消',pos_re4(2,:),12);
            else
                pos_re4 = obj.get_center_pos(getpixelposition(sub_pane_obj2(end)),[60,h_val2-10]);
                str_obj7 = obj.create_button(sub_pane_obj2(end),'确定',pos_re4(1,:),12);
                str_obj8 = [];
            end
            H_out.obj_para = tempobj;
            H_out.obj_button = [str_obj7,str_obj8];
            H_out.h = h;
            
        end
        function pos_re2 = get_grid_pos(obj,obj_parent,total_num,column_num)
            pos_re1 = obj.average_divide_pos_vertical(obj_parent,[1,1],column_num);
            T = ceil(total_num/column_num);
            pos_re2 = zeros(total_num,4);
            for i = 1:size(pos_re1,1)
                sub_pos = obj.average_divide_pos_horizontal(pos_re1(i,:),[1,1],T);
                ind = (1:T)+T*(i-1);
                %if i > 1
                    pos_re2(ind,:) = sub_pos+repmat([0,pos_re1(i,4)*(size(pos_re1,1)-i),0,0],T,1);
                %else
                %    pos_re2(ind,:) = sub_pos;
                %end
            end
            
        end
        function pos_re2 = get_average_divide_pos_vertical(obj,obj_parent,h_value,n)
            
            pos0 = getpixelposition(obj_parent);
            space_values = (pos0(4)-h_value*n)/(n+1);
            pos_re2 = obj.average_divide_pos_vertical(obj_parent,[3,space_values],n);
            %average_divide_pos_vertical;
        end
        function pos_re2 = get_average_divide_pos_horizontal(obj,obj_parent,h_value,n,outier_value)
            if nargin < 5
                outier_value = 3;
            end
            
            pos0 = getpixelposition(obj_parent);
            space_values = (pos0(3)-h_value*n)/(n+1);
            pos_re2 = obj.average_divide_pos_horizontal(obj_parent,[space_values,outier_value],n);
            %average_divide_pos_vertical;
        end
    end
    methods(Static)

        function pos3 =get_center_pos(pos1,pos2)
        %set one gui obj to the center of the other one.
        %get position, pos1 is the bigger one pos2 is the small one
            pos1=pos1(end-1:end);
            pos3 = [(pos1-pos2-60)./2,pos2];
        end
        function pos = get_pos_center(obj_parent,space_values)
            pos1 = getpixelposition(obj_parent);
            pos = [space_values(1),space_values(2),pos1(3:4)-space_values.*2];
        end
        function obj_panels=create_vertical_panel(obj_parent,space_values,ratio_value,sel)
            if nargin < 4
                sel = 0;
            end
            pos1 = getpixelposition(obj_parent);
            width_value = pos1(3)-sum(space_values(1)*2);
            height_value = pos1(4)-space_values(2)*(length(ratio_value)+1);
            T = length(ratio_value);
            ratio_value = ratio_value./sum(ratio_value);
            
            obj_panels = zeros(T,1);
            for i = T:-1:1
                if eq(i,T)
                    sub_pos = [space_values(1),space_values(2),width_value,...
                        height_value*ratio_value(i)];
                else
                    sub_pos0 = getpixelposition(obj_panels(i+1));
                    sub_pos = [sub_pos0(1),sub_pos0(2)+sub_pos0(4)+space_values(2),...
                        width_value,height_value*ratio_value(i)];
                end
                
                obj_panels(i) = uipanel('Parent',obj_parent,'Unit','pixels',...
                    'position',sub_pos);
            end
            if sel > 0
                set(obj_panels,'bordertype','line');
            end
        end
        function obj_panels=create_vertical_panel_manul(obj_parent,space_values,sub_height_value,T,sel)
            if nargin < 5
                sel = 0;
            end
            pos1 = getpixelposition(obj_parent);
            width_value = pos1(3)-sum(space_values(1)*2);            
            
            obj_panels = zeros(T,1);
            for i = T:-1:1
                if eq(i,T)
                    sub_pos = [space_values(1),space_values(2),width_value,...
                        sub_height_value];
                else
                    sub_pos0 = getpixelposition(obj_panels(i+1));
                    sub_pos = [sub_pos0(1),sub_pos0(2)+sub_pos0(4)+space_values(2),...
                        width_value,sub_height_value];
                end
                
                obj_panels(i) = uipanel('Parent',obj_parent,'Unit','pixels',...
                    'position',sub_pos);
            end
            if sel > 0
                set(obj_panels,'bordertype','line');
            end
        end
        function pos_re=get_vertical_pos(obj_parent,space_values,ratio_value)
            pos1 = getpixelposition(obj_parent);
            width_value = pos1(3)-sum(space_values(1)*2);
            height_value = pos1(4)-space_values(2)*(length(ratio_value)+1);
            T = length(ratio_value);
            ratio_value = ratio_value./sum(ratio_value);
            pos_re = zeros(T,4);
            for i = T:-1:1
                if eq(i,T)
                    sub_pos = [space_values(1),space_values(2),width_value,...
                        height_value*ratio_value(i)];
                else
                    sub_pos0 = pos_re(i+1,:);
                    sub_pos = [sub_pos0(1),sub_pos0(2)+sub_pos0(4)+space_values(2),...
                        width_value,height_value*ratio_value(i)];
                end
                pos_re(i,:) = sub_pos;
            end
        end
        function obj_panels=create_horizontal_panel(obj_parent,space_values,ratio_value,sel)
            if nargin < 4
                sel = 0;
            end
            pos1 = getpixelposition(obj_parent);
            width_value = pos1(3)-space_values(1)*(length(ratio_value)+1);
            height_value = pos1(4)-sum(space_values(2)*2);
            T = length(ratio_value);
            ratio_value = ratio_value./sum(ratio_value);
            
            obj_panels = zeros(T,1);
            for i = 1:T
                if eq(i,1)
                    sub_pos = [space_values(1),space_values(2),width_value*ratio_value(i),...
                        height_value];
                else
                    sub_pos0 = getpixelposition(obj_panels(i-1));
                    sub_pos = [sub_pos0(1)+sub_pos0(3)+space_values(1),sub_pos0(2),...
                        width_value*ratio_value(i),height_value];
                end
                
                obj_panels(i) = uipanel('Parent',obj_parent,'Unit','pixels',...
                    'position',sub_pos);
            end
            if sel > 0
                set(obj_panels,'bordertype','line');
            end
        end
        function pos_re=get_horizontal_pos(obj_parent,space_values,ratio_value)
            if nargin < 4
                sel = 0;
            end
            pos1 = getpixelposition(obj_parent);
            width_value = pos1(3)-space_values(1)*(length(ratio_value)+1);
            height_value = pos1(4)-sum(space_values(2)*2);
            T = length(ratio_value);
            ratio_value = ratio_value./sum(ratio_value);
            pos_re = zeros(T,4);
            for i = 1:T
                if eq(i,1)
                    sub_pos = [space_values(1),space_values(2),width_value*ratio_value(i),...
                        height_value];
                else
                    sub_pos0 = pos_re(i-1,:);
                    sub_pos = [sub_pos0(1)+sub_pos0(3)+space_values(1),sub_pos0(2),...
                        width_value*ratio_value(i),height_value];
                end                
                pos_re(i,:) = sub_pos;                
            end
        end
    end
    %position    
    methods(Static)
        function pos_re = average_divide_pos_horizontal(obj_parent,space_values,n)
            if ishandle(obj_parent)
                pos1 = getpixelposition(obj_parent);
            else
                pos1 = obj_parent;
            end
            width_value = (pos1(3)-space_values(1)*(n+1))/n;
            height_value = pos1(4)-sum(space_values(2)*2);
            pos_re = zeros(n,4);
            for i = 1:n
                v1 = space_values(1)*i+width_value*(i-1);
                pos_re(i,:) = [v1,space_values(2),width_value,height_value];
            end
        end
        function pos_re = average_divide_pos_vertical(obj_parent,space_values,n)
            if ishandle(obj_parent)
                pos1 = getpixelposition(obj_parent);
            else
                pos1 = obj_parent;
            end
            height_value = (pos1(4)-space_values(2)*(n+1))/n;
            width_value = pos1(3)-sum(space_values(1)*2);
            pos_re = zeros(n,4);
            for i = 1:n
                v1 = space_values(2)*i+height_value*(i-1);
                pos_re(n-i+1,:) = [space_values(1),v1,width_value,height_value];
            end
        end
    end
    methods(Static)
        function t = create_table(obj_parent)
            t = uitable('parent',obj_parent,'unit','normalized','position',[0,0,1,1]);
        end
        function [tab_obj,tabgp] = create_uitab(obj_parent,pos_value,name_str,unit_sel)
            if nargin < 4
                unit_sel = 'pixels';
            end            
            tabgp = uitabgroup(obj_parent,'unit',unit_sel,'Position',pos_value);
            tab_obj = zeros(size(name_str));
            for i = 1:length(name_str)
                tab_obj(i) = uitab(tabgp,'Title',name_str{i});
            end
        end
        function pane_obj = create_panel(obj_parent,sub_pos,sel)
            if nargin < 3
                sel = 1;
            end
            if eq(sel,1)
                pane_obj = uipanel('Parent',obj_parent,'Unit','pixels',...
                        'position',sub_pos);
            else
                pane_obj = uipanel('Parent',obj_parent,'Unit','normalized',...
                        'position',sub_pos);
            end
        end
        function list_obj = create_listbox(obj_parent,pos,fz)
            if nargin < 2
                pos = [0,0,1,1];
            end
            if nargin < 3
                fz = 12;
            end
            list_obj = uicontrol('parent',obj_parent,...
                                'Style','listbox','Units','normalized',...
                                'position',pos,'fontsize',fz);
        end        
        function list_obj = create_popupmenu(obj_parent,strs,pos,fz)
            if nargin < 3
                pos = [0,0,1,1];
            end
            if nargin < 4
                fz = 12;
            end
            list_obj = uicontrol('parent',obj_parent,...
                                'Style','popupmenu','Units','pixels',...
                                'position',pos,'fontsize',fz,'string',strs);
        end
        function str_obj = create_static_text(obj_parent,strs,pos,fz)
            if nargin < 3
                pos = [0,0,1,1];
            end
            if nargin < 4
                fz = 12;
            end
            str_obj = uicontrol('parent',obj_parent,...
                                'Style','text','Units','pixels',...
                                'position',pos,'fontsize',fz,'string',strs);
        end
        function str_obj = create_edit_text(obj_parent,strs,pos,fz)
            if nargin < 2
                strs = [];
            end
            if nargin < 3
                pos = [0,0,1,1];
            end
            if nargin < 4
                fz = 12;
            end
            str_obj = uicontrol('parent',obj_parent,...
                                'Style','edit','Units','pixels',...
                                'position',pos,'fontsize',fz,'string',strs);
        end
        function str_obj = create_button(obj_parent,strs,pos,fz)
            if nargin < 2
                strs = [];
            end
            if nargin < 3
                pos = [0,0,1,1];
            end
            if nargin < 4
                fz = 12;
            end
            str_obj = uicontrol('parent',obj_parent,...
                                'Style','pushbutton','Units','pixels',...
                                'position',pos,'fontsize',fz,'string',strs);
        end
        function obj_checkbox = create_checkbox(obj_parent,strs,pos,fz)
            if nargin < 2
                strs = [];
            end
            if nargin < 3
                pos = [0,0,1,1];
            end
            if nargin < 4
                fz = 12;
            end
            obj_checkbox = uicontrol('parent',obj_parent,...
                                'Style','checkbox','Units','pixels',...
                                'position',pos,'fontsize',fz,'string',strs);
        end
        function obj_slider = create_slider(obj_parent,vals,pos,fz)
            if nargin < 2
                vals = [];
            end
            if nargin < 3
                pos = [0,0,1,1];
            end
            if nargin < 4
                fz = 12;
            end
            obj_slider = uicontrol('parent',obj_parent,...
                                'Style','slider','Units','normalized',...
                                'position',pos,'fontsize',fz,...
                                'Min',vals(1),'Max',vals(2),'Value',vals(3));
        end
    end
end