%% Section 1. Catalog current tidal datums
%%%-->Paste Station IDs to variable x by entering the following without %
%%%   into the command window
% x = [pasted IDs];

yr = year(datetime(datevec(now)));
save(["TidalDatums_" + num2str(yr) + '.mat'],...
    'x','-mat');

%% Section 2. Determine new and outdated Tidal Datums
% Change filenames below to be the previous and current tidal datum .mat
% files, then run section
previous = load('TidalDatums_2021.mat');
current  = load('TidalDatums_2022.mat');

% remove structures
previous = previous.x;
current = current.x;        

newTD = ismember(current,previous);
newTD = current(newTD==0);
outdatedTD = ismember(previous,current);
outdatedTD = previous(outdatedTD==0);

%% Section 3. get NEW tidal station datums
n=[]; newTD_name={};
wb = waitbar(0,strcat({'Processing 0 of '},num2str(length(newTD))));
for uu = 1:length(newTD)
    waitbar(uu/length(newTD),wb,strcat({'Processing '},num2str(uu),{' of '},num2str(length(newTD))));
    %url = ['https://tidesandcurrents.noaa.gov/benchmarks.html?id=' num2str(newTD(uu))];
    url = ['https://tidesandcurrents.noaa.gov/benchmarks/' num2str(newTD(uu)) '.html'];
    try w = urlread(url);
    catch
        w=[];
    end
    idx = strfind(w,'MEAN HIGHER HIGH WATER');
    mhhw = str2double(w((idx+124):(idx+128)));
    idx = strfind(w,'MEAN HIGH WATER');
    mhw = str2double(w((idx+123):(idx+127)));
    idx = strfind(w,'MEAN SEA LEVEL');
    msl = str2double(w((idx+123):(idx+127)));
    idx = strfind(w,'MEAN TIDE LEVEL');
    mtl = str2double(w((idx+123):(idx+127)));
    idx = strfind(w,'MEAN LOW WATER');
    mlw = str2double(w((idx+123):(idx+127)));
    idx = strfind(w,'MEAN LOWER LOW WATER');
    mllw= str2double(w((idx+124):(idx+128)));
    idx = strfind(w,'NAVD88');
    navd= str2double(w((idx+13):(idx+18))); 
    n(uu,1:7) = [newTD(uu) mlw mtl msl mhw mhhw navd];
    idx = strfind(w,num2str(newTD(uu)));
    idx2= strfind(w(idx(1):idx(1)+50),'>');
    newTD_name{uu,1} = w((idx(1)+8):(idx(1)+idx2(1)-3));
end
close(wb)

%% Section 4. get NEW OPUS info
row = 0;
m={};
wb = waitbar(0,strcat({'Processing 0 of '},num2str(length(newTD))));
for uu = 1:length(newTD)        % for each tide station
    waitbar(uu/length(newTD),wb,strcat({'Processing '},num2str(uu),{' of '},num2str(length(newTD))));
    %url = ['https://tidesandcurrents.noaa.gov/benchmarks.html?id=' num2str(newTD(uu))];
    url = ['https://tidesandcurrents.noaa.gov/benchmarks/' num2str(newTD(uu)) '.html'];
    w = urlread(url);
    idx_all = strfind(w,'BENCH MARK STAMPING:');
    
    stamp={}; stamp_mllw={}; vm={};opus={}; obsdate={};ort={}; ell={}; lat={}; lon={};
    
    for bm = 1:length(idx_all)                      % for each benchmark
        row = row+1;
        idx = idx_all(bm);                      % identify benchmark start point
        bidx = strfind(w((idx+22):(idx+40)),'</B>');
        stamp{bm} = w((idx+22):(idx+20+bidx));
        if sum(stamp{bm} ~= ' ')>0                 % ignore empty stamps
            vidx = strfind(w((idx+100):(idx+300)),'VM#:');
            vm1 = str2double(w((idx+112+vidx):(idx+116+vidx)));
            vm2 = str2double(w((idx+111+vidx):(idx+116+vidx)));
            vm{bm} = max(vm1,vm2);
            oidx = strfind(w((idx):(idx+700)),'OPUS PID#:');
            opus{bm} = w((idx+oidx+10):(idx+oidx+15));
            sidx = strfind(w,stamp{bm});
            sidx = sidx(end);
            stamp_mllw{bm} = w((sidx+44):(sidx+49));  
            
            if isempty(opus{bm}) == 0
                url_opus = ['https://www.ngs.noaa.gov/OPUS/getDatasheet.jsp?PID=' opus{bm}];
                options = weboptions('Timeout', 30);
                wo = webread(url_opus,options);
                if length(wo) < 500
                else
                    obsidx = strfind(wo,'Observed:');
                    obsdate{bm} = wo((obsidx+102):(obsidx + 111));
                    obsdate{bm} = [obsdate{bm}(6:7) '/' obsdate{bm}(9:10) '/' obsdate{bm}(1:4)];
                    latidx = strfind(wo, 'LAT:');
                    coords = wo((latidx+79):(latidx+110));
                    coords_idx = strfind(coords,'&nbsp;');
                    lat{bm} = str2double(coords(1:2))+...
                        str2double(coords((coords_idx(1)+6):(coords_idx(1)+7)))/60+...
                        str2double(coords((coords_idx(2)+6):(coords_idx(2)+13)))/3600;
                    if isnan(lat{bm})
                        lat{bm} = str2double(coords(1:2))+...
                            str2double(coords((coords_idx(1)+6)))/60+...
                            str2double(coords((coords_idx(2)+6):(coords_idx(2)+13)))/3600;
                    end
                    lonidx = strfind(wo, 'LON:');
                    coords = wo((lonidx+79):(lonidx+110));
                    coords_idx = strfind(coords,'&nbsp;');
                    lon{bm} = str2double(coords(1:4))-...
                        str2double(coords((coords_idx(1)+6):(coords_idx(1)+7)))/60-...
                        str2double(coords((coords_idx(2)+6):(coords_idx(2)+13)))/3600;
                    if isnan(lon{bm})
                        lon{bm} = str2double(coords(1:4))-...
                            str2double(coords((coords_idx(1)+6)))/60-...
                            str2double(coords((coords_idx(2)+6):(coords_idx(2)+13)))/3600;
                    end
                    ortidx = strfind(wo,'ORTHO HT:');
                    td = strfind(wo((ortidx):(ortidx+100)),'<td>');
                    td2= strfind(wo((ortidx):(ortidx+100)),'</td>');
                    ort{bm} = wo((ortidx+td+3):(ortidx+td2(2)-2));
                    ellidx = strfind(wo,'ELL HT:');
                    td = strfind(wo((ellidx):(ellidx+100)),'<td>');
                    td2= strfind(wo((ellidx):(ellidx+100)),'</td>');
                    ell{bm} = wo((ellidx+td+3):(ellidx+td2(2)-2));
                    m{row,5} = opus{bm};
                    m{row,6} = obsdate{bm};
                    m{row,7} = str2double(ort{bm});
                    m{row,8} = str2double(ell{bm});
                    m{row,9} = lat{bm};
                    m{row,10}= lon{bm};
                end
            end
            m{row,1} = newTD(uu);
            m{row,2} = stamp{bm};
            m{row,3} = str2double(stamp_mllw{bm});
            m{row,4} = vm{bm};
            
        end
    end
    
end 
close(wb)    
    
t = cell2table(m,'VariableNames',...
    {'Station ID' 'BM Stamping' 'BM Elevation abv MLLW' 'VM' 'OPUS ID'...
    'OPUS Date' 'Ortho Height' 'Ellipsoid Height' 'Lat' 'Lon'});

%% Section 5. OPUS Pull
% Enter date of last pull to serve as the beginning of the search
d_last = '2021-03-01'; % Enter the last pull date here

d_last = datetime(d_last);
opus = {};
row = 0;

% API to search Alaska boundary. It limits output so this is just upper
% half of Alaska.
 % Terms to read JSON and get length for indexing
terms = {'"stamping":' '"lat":' '"lon":' '"ellHt":' '"orthoHt":' '"agency":'};
terms_L = cellfun(@length,terms)+2; % add 2 to account for space and " before entry

latRange = 51:1:71; % it goes from the number to +1 so the last range is 71 to 72 deg N
for ll = 1:length(latRange)
    url = ['https://geodesy.noaa.gov/api/opus/bounds?minlat=',...
        num2str(latRange(ll)),...
        '&minlon=173&maxlat=',num2str(latRange(ll)+1),'&maxlon=310.25'];
    w = urlread(url);
    w = [w '"pid": "']; % add a last pid to trigger the search range for last entry
    idx = strfind(w,'"pid": "');        % index location of all PIDs
    for dd = 1:length(idx)-1      % for each PID 
        txt = w(idx(dd):idx(dd+1));
        didx = strfind(txt,'"observed": ');    % index location of dates
        d = datetime(txt((didx+13):(didx+22)));
        if d>=d_last                            % if it is a new entry
            row = row+1;
            opus{row,1} = txt(9:14);            % record PID
            opus{row,2} = datestr(d);
            for tt = 1:length(terms)            % for each term
                z1 = strfind(txt,terms{tt}); z2 = strfind(txt(z1:(z1+40)),'",');
                opus{row,tt+2} = txt((z1+terms_L(tt)):(z1+z2-2));
            end
        end                          
    end
    [latRange(ll) dd]

end

t_opus = cell2table(opus,"VariableNames",{'PID' 'Date' 'Stamping' 'Lat' 'Lon' 'Ellipsoid' 'Ortho' 'Agency'});
t_opus.Lat = str2double(t_opus.Lat);
t_opus.Lon = str2double(t_opus.Lon);
t_opus.Ellipsoid = str2double(t_opus.Ellipsoid);
t_opus.Ortho = str2double(t_opus.Ortho);

[f,p] = uiputfile('.csv','Save OPUS Pull Data as',['OPUS_pull_',num2str(year(datetime(datevec(now)))),'.csv']);
writetable(t_opus,fullfile(p,f),'Delimiter',',')

%% LEGACY CODE PLEASE IGNORE get all tidal station datums
TideStationID = current;
m={};
wb = waitbar(0,strcat({'Processing 0 of '},num2str(length(TideStationID))));

for uu = 1:length(TideStationID)
    waitbar(uu/length(TideStationID),wb,strcat({'Processing '},num2str(uu),{' of '},num2str(length(TideStationID))));
    mlw =[]; mtl =[]; msl =[]; mhw  =[]; mhhw  =[]; epoch  =[]; period  =[]; status  =[]; statusY =[]; 
    url = ['https://tidesandcurrents.noaa.gov/benchmarks.html?id=' num2str(TideStationID(uu))];
    url = ['https://tidesandcurrents.noaa.gov/benchmarks/' num2str(TideStationID(uu)) '.html'];
    try w = urlread(url);
    idx = strfind(w,'MEAN HIGHER HIGH WATER');
    mhhw = str2double(w((idx+124):(idx+128)));
    idx = strfind(w,'MEAN HIGH WATER');
    mhw = str2double(w((idx+123):(idx+127)));
    idx = strfind(w,'MEAN SEA LEVEL');
    msl = str2double(w((idx+123):(idx+127)));
    idx = strfind(w,'MEAN TIDE LEVEL');
    mtl = str2double(w((idx+123):(idx+127)));
    idx = strfind(w,'MEAN LOW WATER');
    mlw = str2double(w((idx+123):(idx+127)));
    idx = strfind(w,'MEAN LOWER LOW WATER');
    mllw = str2double(w((idx+124):(idx+128)));
    idx = strfind(w,'TIDAL EPOCH:');
    epoch = w((idx+23):(idx+31));
    idx2 = strfind(w,'TIME PERIOD:');
    period = w((idx2+23):(idx-1));
    
    catch
        w=[];
    end
    url2 = ['https://tidesandcurrents.noaa.gov/datums.html?id=' num2str(TideStationID(uu))];
    try w = urlread(url2);
        idx = strfind(w,'Status:');
        idx2 = strfind(w,'Units:');
        status = w((idx+17):(idx2-23));
        statusY = status(end-4:end-1);
    catch
        w=[];
    end
    
    m(uu,1:10) = {TideStationID(uu) mlw mtl msl mhw mhhw epoch period status statusY};
end
close(wb)
t = table(m)

%% LEGACY CODE PLEASE IGNORE get OPUS info
row = 0;
m={};
TideStationID = current;
for uu = 199:length(TideStationID)        % for each tide station

    url = ['https://tidesandcurrents.noaa.gov/benchmarks.html?id=' num2str(TideStationID(uu))];
    url = ['https://tidesandcurrents.noaa.gov/benchmarks/' num2str(TideStationID(uu)) '.html'];
    try w = urlread(url);
    catch
        w=[];
    end
    idx_all = strfind(w,'BENCH MARK STAMPING:');
    
    stamp={}; stamp_mllw={}; vm={};opus={}; obsdate={};ort={}; ell={}; lat={}; lon={};
    
    for bm = 1:length(idx_all)                      % for each benchmark
        row = row+1;
        idx = idx_all(bm);                      % identify benchmark start point
        bidx = strfind(w((idx+22):(idx+40)),'</B>');
        stamp{bm} = w((idx+22):(idx+20+bidx));
        if sum(stamp{bm} ~= ' ')>0                 % ignore empty stamps
            vidx = strfind(w((idx+100):(idx+300)),'VM#:');
            vm1 = str2double(w((idx+112+vidx):(idx+116+vidx)));
            vm2 = str2double(w((idx+111+vidx):(idx+116+vidx)));
            vm{bm} = max(vm1,vm2);
            oidx = strfind(w((idx+400):(idx+700)),'OPUS PID#:');
            opus{bm} = w((idx+410+oidx):(idx+oidx+415));
            sidx = strfind(w,stamp{bm});
            sidx = sidx(end);
            stamp_mllw{bm} = w((sidx+44):(sidx+49));  
            
            if isempty(opus{bm}) == 0;
                url_opus = ['https://www.ngs.noaa.gov/OPUS/getDatasheet.jsp?PID=' opus{bm}];
                wo = webread(url_opus,'Timeout',20);
                if length(wo) < 500
                else
                    obsidx = strfind(wo,'Observed:');
                    obsdate{bm} = wo((obsidx+102):(obsidx + 111));
                    obsdate{bm} = [obsdate{bm}(6:7) '/' obsdate{bm}(9:10) '/' obsdate{bm}(1:4)];
                    latidx = strfind(wo, 'LAT:');
                    lat{bm} = [wo((latidx+79):(latidx+81)) ' ' wo((latidx+88):(latidx+90)) ' ' wo((latidx+97):(latidx+105))];
                    lonidx = strfind(wo, 'LON:');
                    lon{bm} = [wo((lonidx+79):(lonidx+83)) ' ' wo((lonidx+90):(lonidx+92)) ' ' wo((lonidx+99):(lonidx+107))];
                    ortidx = strfind(wo,'ORTHO HT:');
                    td = strfind(wo((ortidx):(ortidx+100)),'<td>');
                    td2= strfind(wo((ortidx):(ortidx+100)),'</td>');
                    ort{bm} = wo((ortidx+td+3):(ortidx+td2(2)-2));
                    ellidx = strfind(wo,'ELL HT:');
                    td = strfind(wo((ellidx):(ellidx+100)),'<td>');
                    td2= strfind(wo((ellidx):(ellidx+100)),'</td>');
                    ell{bm} = wo((ellidx+td+3):(ellidx+td2(2)-2));
                    m{row,5} = opus{bm};
                    m{row,6} = obsdate{bm};
                    m{row,7} = str2double(ort{bm});
                    m{row,8} = str2double(ell{bm});
                    m{row,9} = lat{bm};
                    m{row,10}= lon{bm};
                end
            end
            m{row,1} = TideStationID(uu);
            m{row,2} = stamp{bm};
            m{row,3} = str2double(stamp_mllw{bm});
            m{row,4} = vm{bm};
            
        end
    end
    
end 
    
    
t = table(m)
    
