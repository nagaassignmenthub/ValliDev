import { LightningElement, track } from 'lwc';
import checkDuplicateAndCreateLead from '@salesforce/apex/LeadConversionController.checkDuplicateAndCreateLead';
import convertLeadToOpportunity from '@salesforce/apex/LeadConversionController.convertLeadToOpportunity';
import getWeatherByCity from '@salesforce/apex/WeatherServiceCallout.getWeatherByCity';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class SignUpForm extends LightningElement {
    @track fullName = '';
    @track opptyName = '';
    @track email = '';
    @track phone = '';
    @track emirate = '';
    @track emailError = '';
    @track phoneError = '';
    @track emirateError = '';
    @track serverMessage = '';
    @track leadId = '';
    @track opportunityId = '';
    @track showConversionModal = false;
    @track showSuccessButton = false;
    showSignUp = true;
    showSignUpSummary = false;
    temp = '';
    @track loading = false;

    //Emirate Picklist Options
    emirateOptions = [
        { label: 'Abu Dhabi', value: 'Abu Dhabi' },
        { label: 'Dubai', value: 'Dubai' },
        { label: 'Sharjah', value: 'Sharjah' },
        { label: 'Ajman', value: 'Ajman' },
        { label: 'Fujairah', value: 'Fujairah' },
        { label: 'Ras Al Khaimah', value: 'Ras Al Khaimah' },
        { label: 'Umm Al Quwain', value: 'Umm Al Quwain' }
    ];

    //Setting value for view record of lead
    get leadUrl() {
        return `/lightning/r/Lead/${this.leadId}/view`;
    }
    //Setting value for view record of Oppty
    get opptyUrl() {
        return `/lightning/r/Opportunity/${this.opptyId}/view`;
    }

    //Email unwanted character remove
    get femail() {
        return this.email.replaceAll("(or)", "");
    }

    //Valiation of the input fields
    handleChange(event) {
        const field = event.target.dataset.id;
        this[field] = event.target.value;
        this.emailError = '';
        this.phoneError = '';
        this.emirateError = '';
        this.serverMessage = '';
    }

    validateEmail(email) {
        const regex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
        return regex.test(email);
    }

    validateUAEPhone(phone) {
        const regex = /^(?:\+971|971|0)?(50|51|52|54|55|56|58)\d{7}$/;
        return regex.test(phone);
    }


    async handleSubmit() {
        let valid = true;

        if (!this.validateEmail(this.email)) {
            this.emailError = 'Invalid email format';
            valid = false;
        }

        if (!this.validateUAEPhone(this.phone)) {
            this.phoneError = 'Invalid UAE phone number';
            valid = false;
        }

        if (!this.emirate) {
            this.emirateError = 'Please select an Emirate';
            valid = false;
        }

        if (!valid) return;

        try {
            alert(this.phone);

            // Successful validation lead creation
            const result = await checkDuplicateAndCreateLead({
                name: this.fullName,
                email: this.email,
                phone: this.phone,
                emirate: this.emirate
            });

            if (result.success) {
                this.loading = false;
                this.serverMessage = 'Signup successful. Thank you!';
                this.opptyName = this.fullName;
                this.leadId = result.leadId;
                this.showSignUp = false;
                this.showConversionModal = true;
            } else {
                this.serverMessage = result.message;
            }
        } catch (error) {
            this.serverMessage = 'Error: ' + (error.body?.message || error.message);
        }
    }
    //Lead conversion and weather API call
    async handleConvertLead() {
        try {
            this.showConversionModal = false;
            this.loading = true;
            //lead conversion
            const result = await convertLeadToOpportunity({
                leadId: this.leadId,
                opptyName: this.opptyName

            });

            if (result.success) {
                //Weather API call
                const weather = await getWeatherByCity({
                    city: result.emirateCity,
                    opptyId: result.opportunityId
                });

                const msg = weather.status
                    ? `Lead converted. Temperature in ${weather.name}: ${weather.main.temp}°C`
                    : 'Lead converted to Opportunity successfully!';

                this.temp = weather.main.temp;
                this.loading = false;

                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: msg,
                        variant: 'success'
                    })
                );

                this.serverMessage = '';
                this.opportunityId = result.opportunityId;
                this.showSuccessButton = true;
                this.showSignUpSummary = true;
            } else {
                this.serverMessage = '';
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Failed',
                        message: result.message,
                        variant: 'error'
                    })
                );
            }
        } catch (error) {
            this.serverMessage = 'Error: ' + (error.body?.message || error.message);
        }
    }

    //cancel button actions
    handleCancelConversion() {
        this.serverMessage = 'Lead created but not converted.';
        this.showConversionModal = false;

    }

    //back button actions

    handleBackClick() {
        this.serverMessage = '';
        this.showSignUpSummary = false;
        this.showSignUp = true;
        this.fullName = '';
        this.email = '';
        this.phone = '';
        this.emirate = '';
    }
}