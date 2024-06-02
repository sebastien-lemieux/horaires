## Loads programme structures

using TidierVest, Gumbo, DataFrames, HTTP

prog = read_html("https://admission.umontreal.ca/programmes/baccalaureat-en-bio-informatique/structure-du-programme/")
#prog = read_html("https://admission.umontreal.ca/programmes/maitrise-en-bio-informatique/structure-du-programme/")

blocs = html_elements(prog, [".bloc"])

bloc_noms = String[]
sigles = String[]
cour_noms = String[]
cour_credit = String[]

for b in blocs
    bn = split(html_text3(first(html_elements(b, "h4"))))[2]
    cours = html_elements(b, ".cour-detailles")
    for c in cours
        ci = html_elements(c, ".cour-intro")
        push!(bloc_noms, bn)
        push!(sigles, html_text3(first(html_elements(ci, ".stretched-link"))))
        push!(cour_noms, html_text3(first(html_elements(ci, "span"))))
        push!(cour_credit, first(html_text3(html_elements(c, ".cour-credit"))))
    end
end

prog_df = DataFrame(bloc=bloc_noms, sigle=sigles, nom=cour_noms, credit=[parse(Float32, first(split(c))) for c in cour_credit])

## Fetch one course schedule from the "Centre etudiant" (Not working)

url = "https://academique-dmz.synchro.umontreal.ca/psc/acprpr9_pub/EMPLOYEE/HRMS/c/SA_LEARNER_SERVICES.CLASS_SEARCH.GBL"
header = Dict(raw"CLASS_SRCH_WRK2_STRM$35$"=>"2241",
raw"SSR_CLSRCH_WRK_SUBJECT$0" => "BCM",
raw"SSR_CLSRCH_WRK_SSR_EXACT_MATCH1$1" => "E",
raw"SSR_CLSRCH_WRK_CATALOG_NBR$1" => "2003")

r = HTTP.post(url, body=header) # , header, body)
h = parsehtml(String(r.body))
println(h)

html_elements(h, raw"option") |> println


url = "https://academique-dmz.synchro.umontreal.ca/psc/acprpr9_pub/EMPLOYEE/HRMS/c/SA_LEARNER_SERVICES.CLASS_SEARCH.GBL"

str = """
Accept: */*
Accept-Encoding: gzip, deflate, br, zstd
Accept-Language: en-US,en;q=0.9,fr-CA;q=0.8,fr;q=0.7,is;q=0.6
Connection: keep-alive
Content-Length: 1468
Content-Type: application/x-www-form-urlencoded
Cookie: _fbp=fb.1.1639756151006.1901109885; ajs_user_id=60364ea6c897f2b2f8f1676f7a1404933b681d91; ajs_anonymous_id=49cb841b-98eb-4526-8bbc-4c66e5ea01d7; _ga_QBXTQ5QKV9=GS1.1.1684164794.1.1.1684164855.0.0.0; _ga_JYVW97H90D=GS1.1.1692719337.1.1.1692719525.33.0.0; _ga_5EY3G22FG5=GS1.1.1692719337.1.1.1692719525.33.0.0; _ga_BE54NZRWXQ=GS1.2.1695164133.2.1.1695164918.60.0.0; _ga_3D5DV2FLN3=GS1.2.1696448211.2.1.1696448267.4.0.0; _ga_08KVJQJ84Z=GS1.1.1696448211.3.1.1696449301.60.0.0; PS_DEVICEFEATURES=width:5120 height:1440 pixelratio:1 touch:0 geolocation:1 websockets:1 webworkers:1 datepicker:1 dtpicker:1 timepicker:1 dnd:1 sessionstorage:1 localstorage:1 history:1 canvas:1 svg:1 postmessage:1 hc:0 maf:0; _ga_ZXJF11YT5X=GS1.1.1697206077.1.1.1697206141.60.0.0; _ga_C0XM8J6CKG=GS1.1.1697477772.2.0.1697477772.0.0.0; _sctr=1%7C1702443600000; _scid_r=e990d681-9470-436d-b0ed-e0848d2e9f9c; _uetvid=22a51ea05f5111ec9705055c11ffd59f; _ga_8K78BPQ5LF=GS1.2.1703170066.5.1.1703170068.0.0.0; _ga_W2MK0FY8Y3=GS1.2.1705020158.1.1.1705020169.0.0.0; _ga_4XQX40CYFB=GS1.1.1705020043.2.1.1705020860.0.0.0; _ga_SK92GNVM0C=GS1.1.1705586709.1.1.1705586744.37.0.0; _ga_NS7BWVPLTM=GS1.1.1705617372.2.1.1705617469.54.0.0; _ga_ZREFLJZJXL=GS1.1.1706386062.4.1.1706386234.60.0.0; _ga_5XWBXP7MPF=GS1.1.1706386468.5.1.1706386526.3.0.0; _ga_75L3XP7X1R=GS1.1.1706386468.5.1.1706386526.3.0.0; _gcl_au=1.1.683048370.1707943888; _ga_5TQ9VNSYY2=GS1.1.1708024154.4.1.1708024258.53.0.0; _ga_D9Y376M6XK=GS1.1.1708612175.1.1.1708612212.0.0.0; _ga_1WPM1M7ZTN=GS1.1.1710253905.1.1.1710254063.60.0.0; _ga_SGNLEXPKRH=GS1.1.1710434145.7.1.1710434586.60.0.0; _ga_2Y51JQ7R4J=GS1.2.1712021843.5.0.1712021843.0.0.0; _ga_461NH5ZKDQ=GS1.1.1713365333.1.1.1713366267.60.0.0; _ga_ZQEHK1XKDX=GS1.2.1713367272.5.1.1713367295.0.0.0; _ga_ZY9DJS7MK9=GS1.1.1713369398.1.1.1713370962.0.0.0; _ga_1S1512585X=GS1.1.1713375438.7.1.1713376791.60.0.0; _ga_CYWN76CHMN=GS1.1.1713375438.6.1.1713376791.60.0.0; _ga_7DQM4V7B8F=GS1.1.1713376977.6.0.1713376977.60.0.0; _ga_FC09NH8K8E=GS1.1.1713376977.23.0.1713376977.0.0.0; _clck=1qczqsp%7C2%7Cfl3%7C0%7C1442; _ga_WE1D4FK676=GS1.1.1713634410.18.1.1713634434.0.0.0; _ga_FJ9KCTL5RK=GS1.1.1713634410.5.1.1713634434.36.0.0; _ga_Q6Y1FGW6QF=GS1.1.1713637213.4.1.1713637291.0.0.0; _ga_QHZTSGD6VK=GS1.2.1713714686.25.0.1713714686.0.0.0; _ga_E4RXVMJRMQ=GS1.1.1713714685.17.1.1713714855.60.0.0; UdeM_jms=%03%C6m%3F%F8%BCA%18%A0%C9%01%D3%EF%CB%15%02%EFcb(%5E%3C%FA%95%83%24%DD%C0%8C%FBv%D9g%91n%7B%22%09%8E%40%E2.V%0E%B0%0A%B4%8E%A7%E8%D1)7%14%97%DB%AB%08%A8%BA%19%CBJ8%9B%E8L%22%ABDg%0C-%CFR%1D%84%9B%E3%A6%13p%00%00%00%01; PS_DEVICEFEATURES=width:5120 height:1440 pixelratio:1 touch:0 geolocation:1 websockets:1 webworkers:1 datepicker:1 dtpicker:1 timepicker:1 dnd:1 sessionstorage:1 localstorage:1 history:1 canvas:1 svg:1 postmessage:1 hc:0 maf:0; _gcl_aw=GCL.1713997354.CjwKCAjw26KxBhBDEiwAu6KXt0aQVjxbDa_D_1REkY50PxGKZJuArJf8pxRMBZh0-9H7u0ol8J7J5hoCqjsQAvD_BwE; _ga=GA1.1.1456948634.1639756151; BIGipServerAcademique.synchro-pool=214071306.22555.0000; acprprwbl25=1s4THbOrLWJYQ70JUp2XE43oLBkVo-xq!2002172259; SignOnDefault=; rhprprwbl25=unYTHejq8KgLzqlOXpAi_iP6enOwtR8X!-1701429201; BIGipServerRh.synchro-Pool=213940234.22555.0000; fnprprwbl25=p6UTHejs6hRGmW8RKWscv_V5belD6BFk!-916527764; BIGipServerFinances.synchro-Pool=180451338.22555.0000; upprprwbl15=hEwTHejz5wQgrlRb2slW_IKVS07lImve!-286931013; BIGipServerWww.synchro-Pool=168065034.22555.0000; ExpirePage=https://academique.synchro.umontreal.ca/psp/acprpr9/; ps_theme=node:SA portal:EMPLOYEE theme_id:DEFAULT_THEME_FLUID css:DEFAULT_THEME_FLUID accessibility:N formfactor:3 piamode:2; LastMRH_Session=2710a9ca; MRHSession=6f40d05f0a734475c34aa5222710a9ca; _ga_TK9KFPW33N=GS1.1.1714243137.52.1.1714243146.0.0.0; _ga_LN9QV0EFSC=GS1.1.1714272784.179.1.1714273124.32.0.0; _ga_TNZ9KQ9QXF=GS1.1.1714272784.84.1.1714273124.32.0.0; acprprwbl35=qUAio_6BtCdXspKNj3_adyVxtj_F3o3E!519745898; PS_LOGINLIST=https://academique-dmz.synchro.umontreal.ca/acprpr9_pub https://academique.synchro.umontreal.ca/acprpr9; PS_TOKEN=qgAAAAQDAgEBAAAAvAIAAAAAAAAsAAAABABTaGRyAk4Adwg4AC4AMQAwABTkNXw0pDB3+A+FT5q05R63XYXKFmoAAAAFAFNkYXRhXnicHclLDkBAEIThfxBLS7cgjPHYygQriRjWjuFyDqfoxVdd3TeQxJExyifin/xk5WLEy4WTicBB6pnZyTa1Wf3SP+AsFRZHofy09LJmoKT9dTTyuwzaWjp4ASapDTo=; PS_TokenSite=https://academique-dmz.synchro.umontreal.ca/psc/acprpr9_pub/?acprprwbl35; PS_LASTSITE=https://academique-dmz.synchro.umontreal.ca/psc/acprpr9_pub/; BIGipServerAcademique-dmz.synchro-pool=!xuEuh81a51SYYK5DdxWO8j+RL+vWJt1iPiXkSn4Auwc32iJd6f2lHvxEv65ykjutDlf507MsQa83Ng==; psback=%22%22url%22%3A%22https%3A%2F%2Facademique-dmz.synchro.umontreal.ca%2Fpsc%2Facprpr9_pub%2FEMPLOYEE%2FHRMS%2Fc%2FSA_LEARNER_SERVICES.CLASS_SEARCH.GBL%22%20%22label%22%3A%22zzz%22%20%22origin%22%3A%22PIA%22%20%22layout%22%3A%220%22%20%22refurl%22%3A%22https%3A%2F%2Facademique-dmz.synchro.umontreal.ca%2Fpsc%2Facprpr9_pub%2FEMPLOYEE%2FHRMS%22%22; PS_TOKENEXPIRE=28_Apr_2024_03:39:47_GMT
Host: academique-dmz.synchro.umontreal.ca
Origin: https://academique-dmz.synchro.umontreal.ca
Referer: https://academique-dmz.synchro.umontreal.ca/psc/acprpr9_pub/EMPLOYEE/HRMS/c/SA_LEARNER_SERVICES.CLASS_SEARCH.GBL
Sec-Fetch-Dest: empty
Sec-Fetch-Mode: cors
Sec-Fetch-Site: same-origin
User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36
sec-ch-ua: "Chromium";v="124", "Google Chrome";v="124", "Not-A.Brand";v="99"
sec-ch-ua-mobile: ?0
sec-ch-ua-platform: "Windows"
"""

header = Dict{String, String}()
for l in split(str, '\n')
    length(l) == 0 && break
    m = match(r"^([^:]*): (.*)$", l)
    println(m[1], " => ", m[2])
    header[m[1]] = m[2]
end

body = raw"ICAJAX=1&ICNAVTYPEDROPDOWN=0&ICType=Panel&ICElementNum=0&ICStateNum=23&ICAction=CLASS_SRCH_WRK2_SSR_PB_CLASS_SRCH&ICModelCancel=0&ICXPos=0&ICYPos=0&ResponsetoDiffFrame=-1&TargetFrameName=None&FacetPath=None&ICFocus=&ICSaveWarningFilter=0&ICChanged=-1&ICSkipPending=0&ICAutoSave=0&ICResubmit=0&ICSID=1uE6pVbtG%2FkgJs81myC%2B5sRlkvkG1tlAgGa1NRroceU%3D&ICActionPrompt=false&ICBcDomData=UnknownValue&ICPanelName=&ICFind=&ICAddCount=&ICAppClsData=&CLASS_SRCH_WRK2_INSTITUTION$31$=UDM00&CLASS_SRCH_WRK2_STRM$35$=2241&SSR_CLSRCH_WRK_SUBJECT$0=BCM&SSR_CLSRCH_WRK_SSR_EXACT_MATCH1$1=E&SSR_CLSRCH_WRK_CATALOG_NBR$1=2003&SSR_CLSRCH_WRK_ACAD_CAREER$2=1CYC&SSR_CLSRCH_WRK_CRSE_ATTR_VALUE$3=&SSR_CLSRCH_WRK_CAMPUS$4=&SSR_CLSRCH_WRK_SSR_OPEN_ONLY$chk$5=N&SSR_CLSRCH_WRK_SSR_START_TIME_OPR$6=GE&SSR_CLSRCH_WRK_MEETING_TIME_START$6=&SSR_CLSRCH_WRK_SSR_END_TIME_OPR$6=LE&SSR_CLSRCH_WRK_MEETING_TIME_END$6=&SSR_CLSRCH_WRK_INCLUDE_CLASS_DAYS$7=J&SSR_CLSRCH_WRK_SUN$chk$7=&SSR_CLSRCH_WRK_MON$chk$7=&SSR_CLSRCH_WRK_TUES$chk$7=&SSR_CLSRCH_WRK_WED$chk$7=&SSR_CLSRCH_WRK_THURS$chk$7=&SSR_CLSRCH_WRK_FRI$chk$7=&SSR_CLSRCH_WRK_SAT$chk$7=&SSR_CLSRCH_WRK_SSR_EXACT_MATCH2$8=B&SSR_CLSRCH_WRK_LAST_NAME$8=&SSR_CLSRCH_WRK_CLASS_NBR$9=&SSR_CLSRCH_WRK_DESCR$10=&SSR_CLSRCH_WRK_SSR_UNITS_MIN_OPR$11=GE&SSR_CLSRCH_WRK_UNITS_MINIMUM$11=&SSR_CLSRCH_WRK_SSR_UNITS_MAX_OPR$11=LE&SSR_CLSRCH_WRK_UNITS_MAXIMUM$11=&SSR_CLSRCH_WRK_SSR_COMPONENT$12=&SSR_CLSRCH_WRK_INSTRUCTION_MODE$13=&SSR_CLSRCH_WRK_LOCATION$14="

r = HTTP.post(url, header, body)
h = parsehtml(String(r.body))
println(h)

html_elements(h, raw"span") |> println

HTTP.get("https://academique-dmz.synchro.umontreal.ca/psc/acprpr9_pub/EMPLOYEE/HRMS/c/SA_LEARNER_SERVICES.CLASS_SEARCH.GBL").body |> String