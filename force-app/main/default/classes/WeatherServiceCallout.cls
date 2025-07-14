public class WeatherServiceCallout {
   
    
    // custom label to store API key
    public static final String API_KEY =system.label.key_Api; 
    public class WeatherMain {
        @AuraEnabled public Decimal temp;
         @AuraEnabled public Decimal feels_like;
         @AuraEnabled  public Decimal temp_min;
         @AuraEnabled public Decimal temp_max;
    }

    public class WeatherResponse {
        @AuraEnabled public String name; // City name
         @AuraEnabled public Boolean status;
         @AuraEnabled public WeatherMain main;
    }
    @AuraEnabled
    public static WeatherResponse getWeatherByCity(String city, string opptyId) {
        //city='Abu Dhabi';
        List<Opportunity> OpptyList=new List<Opportunity>();
        try {
        

            HttpRequest req = new HttpRequest();
            //req.setEndpoint(url); //Using Named creds
            req.setEndPoint('callout:WeatherService/data/2.5/weather?q='+EncodingUtil.urlEncode(city, 'UTF-8')+'&appid='+API_KEY+'&units=metric');
            req.setMethod(system.label.get);

            Http http = new Http();
            HttpResponse res = http.send(req);

            if (res.getStatusCode() == 200) {
                    WeatherResponse weather = (WeatherResponse) JSON.deserialize(res.getBody(), WeatherResponse.class);
                weather.status=true;
                Opportunity opp=new Opportunity();
                opp.Id=opptyId;
                opp.WeatherData__c=String.valueOf(weather);
                OpptyList.add(opp);
                //update custom field with response on oppty
                if(OpptyList.size()>0)
                   {
                       update OpptyList;
                   }    
                System.debug('City: ' + weather.name);
                System.debug('status: ' + weather.status);
                System.debug('Temperature: ' + weather.main.temp + '°C');
                System.debug('Feels Like: ' + weather.main.feels_like + '°C');
                System.debug('Min: ' + weather.main.temp_min + '°C');
                System.debug('Max: ' + weather.main.temp_max + '°C');
                return weather;
            } else {
                System.debug('Error: ' + res.getStatus() + ' - ' + res.getBody());
                WeatherResponse weather=new WeatherResponse();
                weather.name=city;
                weather.status=false;
                return weather;
                
            }
        } catch (Exception e) {
            System.debug('Exception: ' + e.getMessage());
            WeatherResponse weather=new WeatherResponse();
            weather.name=city;
            weather.status=false;
            return weather;
        }
    }
}