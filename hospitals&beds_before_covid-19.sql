select * from "AYUSHHospitals";
select * from emp_sic;
select * from hnb_mod;
select * from hnb_railways;
select * from hnb_statewise;
select * from total_hnb_rua;

-- Q1) List the total number of hospitals and beds in each state/UT under the Ministry of Ayush Government of India.

	   select "State / UT", total_hosp,total_beds
	   from "AYUSHHospitals";

	   
-- Q2) Find the total number of beds in hospitals run by the Ministry of Defence for the state of 'Delhi'?

	   select "No. of beds" 
	   from hnb_mod
	   where "states/ut" Like 'Delhi';

-- Q3) Retrieve the number of rural hospitals and beds for the state of 'Kerala'.

       select "States/UTs", "No. Rural hospitals", "Beds Rural hospitals"
	   from total_hnb_rua
	   where "States/UTs" like 'Kerala';

-- Q4) Show the names of States/UTs and the total number of beds available in hospitals run by local bodies, where the number of hospitals is greater than 5000.


       select "States/UTs", "Beds Rural hospitals" 
	   from total_hnb_rua
	   where "No. Rural hospitals" > 500;

-- Q5) How many states/UTs have more than 10 hospitals run by State Insurance Corporation?


	   select count("States /UTs")
	   from emp_sic
	   where "Total No. of Hospital" >10;
	   
-- Q6) List the states/UTs with the total number of government hospitals and beds in rural areas. Include the state/UT name, number of government hospitals, and number of beds.

       select "State / UT" , SUM (a.localbody_hosp + r.rural_hosp) as hospital ,sum (a.localbody_beds + r.ruralhosp_beds) as beds
	   from "AYUSHHospitals" as a
	   left join total_hnb_rua as r
	   on a."State / UT"=r."States/UTs"
	   group by "State / UT";
	   

-- Q7) List the average number of beds per zone for hospitals operated by the Ministry of Railways across various zones.


       select "Zone / PU", avg(beds/hospitals) as avg_beds
	   from hnb_railways
	   group by "Zone / PU";
	   

-- Q8) Calculate the total number of hospitals across PHCs, CHCs, SDHs, and DHs. Display only those states where the total number of beds is greater than 500.

	  select "states/ut", 
      sum(cast("PHC" as integer) + cast("CHC" as integer) + cast("SDH" as integer) + cast("DH" as integer)) as total_hospitals
      from hnb_statewise 
      group by  "states/ut"
      having sum(cast("PHC" as integer) + cast("CHC" as integer) + cast("SDH" as integer) + cast("DH" as integer)) > 500;


--Q9) Identify the states/UTs that have a higher number of hospitals established by Ministry of Defence compared to the average number of established by Employee State Insurance Corporation.

       select "states/ut"
	   from hnb_mod
	   where "No. of Hospitals" > (select avg( "Total No. of Hospital") from emp_sic);


-- Q10) Write a query to list the states/UTs where the total number of beds in government hospitals established by the Ministry of Ayush is less than the sum of beds in rural and urban hospitals established by rural and urban bodies.

       select a."State / UT"
       from "AYUSHHospitals" a
       join ( select "States/UTs",  sum(ruralhosp_beds + urbanhosp_beds) as total_rural_urban_beds
              from total_hnb_rua
              group by "States/UTs") as r
       on a."State / UT" = r."States/UTs"
       where a.govt_beds < r.total_rural_urban_beds;

	
-- Q11) Calculate the percentage distribution of hospital types (PHCs, CHCs, SDHs, DHs) for each state and compare it to the percentage distribution of government hospitals established by the Ministry of Ayush.List the states where the difference in distributions exceeds 10%.


with hospital_types as (

       select  "states/ut",  
       sum(cast("PHC" as numeric)) * 100.0 / sum(cast("PHC" as numeric) + cast("CHC" as numeric) + cast("SDH" as numeric) + cast("DH" as numeric)) as pct_phc,
        
       sum(cast("CHC" as numeric)) * 100.0 / sum(cast("PHC" as numeric) + cast("CHC" as numeric) + cast("SDH" as numeric) + cast("DH" as numeric)) as pct_chc,
     
       sum(cast("SDH" as numeric)) * 100.0 / sum(cast("PHC" as numeric) + cast("CHC" as numeric) + cast("SDH" as numeric) + cast("DH" as numeric)) as pct_sdh,
       
       sum(cast("DH" as numeric)) * 100.0 /sum(cast("PHC" as numeric) + cast("CHC" as numeric) + cast("SDH" as numeric) + cast("DH" as numeric)) as pct_dh
      from hnb_statewise 
      group by "states/ut"  
),


ayush_distribution as (
        select "State / UT",  
        sum(cast("Govt_Hospitals" as numeric)) * 100.0 / sum(sum(cast("Govt_Hospitals" as numeric))) over () as pct_ayush
        from "AYUSHHospitals" 
        group by "State / UT"  
)

        select h."states/ut",h.pct_phc, h.pct_chc, h.pct_sdh, h.pct_dh,a.pct_ayush  
        from hospital_types h
        join ayush_distribution a on h."states/ut" = a."State / UT"  
		
        where abs(h.pct_phc - a.pct_ayush) > 10 or
         abs(h.pct_chc - a.pct_ayush) > 10 or
         abs(h.pct_sdh - a.pct_ayush) > 10 or
         abs(h.pct_dh - a.pct_ayush) > 10;

--Q12) Calculate the total number of beds in hospitals run by the Ministry of Defence and compare it to the total number of beds in hospitals run by local bodies for each state/UT. Identify and list the states/UTs where the difference in bed counts is greater than 1,000.

with bed_counts_mod as (
    select "states/ut",
    sum(cast("No. of Hospitals" as numeric)) as total_defence_beds
    from "hnb_mod"
    group by "states/ut"),

bed_counts_localbodies AS (
    select "States/UTs",
    sum(cast("ruralhosp_beds" as numeric) + cast("urbanhosp_beds" as numeric)) as total_local_beds
    from total_hnb_rua
    group by "States/UTs")

    select m."states/ut",m.total_defence_beds,l.total_local_beds,
    abs(m.total_defence_beds - l.total_local_beds) as bed_difference
    from bed_counts_mod m
    join bed_counts_localbodies l
    on m."states/ut" = l."States/UTs"
    where  abs(m.total_defence_beds - l.total_local_beds) > 1000;

--Q13) Rank the zones based on the total number of beds available in hospitals established by the Ministry of Railways, displaying the rank, zone, and total number of beds in descending order.


     select rank() over (order by sum("beds") desc) as rank,"Zone / PU",
     sum("beds") as total_beds
     from "hnb_railways" 
     group by "Zone / PU"
     order by 
     rank;


--Q14) List the states/UTs where the number of beds in hospitals managed by the Employee State Insurance Corporation exceeds the number of beds in hospitals managed by the Ministry of Defence for that state/UT.

       select  e."States /UTs",e."Total No. of Beds" as esic_beds,d."No. of beds" as defence_beds
       from emp_sic e  
       join hnb_mod d  
       on e."States /UTs" = d."states/ut"
       where e."Total No. of Beds" > d."No. of beds";


--Q15) List total number of beds in government hospitals and local body hospitals for each state/UT. Then, identify the states/UTs where this combined total of beds is below the 25th percentile of the combined totals across all states/UTs.

  with combined_beds as (
        select a."State / UT",sum(cast(a."govt_beds" as numeric)) + sum(cast(a."localbody_beds" as numeric)) as total_beds
        from "AYUSHHospitals" a
        group by a."State / UT"
    
  union all

        select t."States/UTs",sum(cast(t."ruralhosp_beds" as numeric)) + sum(cast(t."urbanhosp_beds" as numeric)) as total_beds
        from "total_hnb_rua" t
        group by t."States/UTs"),

  percentile as (
        select percentile_cont(0.25) within group (order by total_beds) as p25
        from combined_beds)

        select c."State / UT",c.total_beds
        from combined_beds c
        join percentile p
        on c.total_beds < p.p25
        group by c."State / UT", c.total_beds;
