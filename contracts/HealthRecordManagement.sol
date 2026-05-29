// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.7.0 <0.9.0;

import "hardhat/console.sol";

contract HealthRecordManagement {
    address private owner;

    struct HealthRecord {
        uint256 recordId;
        address patientAddress;
        int16 height;
        int16 weight;
        string bloodPressure;
        string cholesterol;
        string diagnosis;
        string treatment;
        uint256 timeStamp;
        address addedBy;
    }

    struct Doctor {
        address doctorAddress;
        string qualification;
        string specialization;
        bool status;
        uint256 timeStamp;
        address addedBy;
    }

    Doctor[] private doctors;

    mapping(address => bool) private doctorAuthorizationStatus;
    mapping(address => address[]) private patientToDoctors;
    mapping(address => address[]) private doctorToPatients;
    mapping(address => HealthRecord[]) private patientHealthRecords;

    event RegisterAuthorizedDoctor(
        address indexed doctorAddress,
        string qualification,
        string specialization,
        bool status,
        uint256 timeStamp,
        address indexed registeredBy
    );

    event DeRegisterAuthorizedDoctor(
        address indexed doctorAddress,
        bool deregisterStatus,
        string reason,
        uint256 timeStamp,
        address indexed deRegisteredBy
    );

    event BookAppointmentAndGrantAccess(
        address indexed fromPatientAddress,
        address indexed toHealthServiceProviderAddress,
        string reason,
        uint256 timeStamp
    );

    event MarkAppointmentDoneAndRevokeAccess(
        address indexed fromPatientAddress,
        address indexed toHealthServiceProviderAddress,
        uint256 timeStamp
    );
    
    event AddHealthRecord(
        uint256 recordId,
        address indexed patientAddress,
        int16 height,
        int16 weight,
        string bloodPressure,
        string cholesterol,
        string diagnosis,
        string treatment,
        uint256 timeStamp,
        address indexed addedBy
    );



    modifier onlyOwner() {
        require(msg.sender == owner, "Only contract owner can perform this action");
        _;
    }

    modifier onlyAuthorizedHealthServiceProvider() {
        require(doctorAuthorizationStatus[msg.sender] == true, "Only authorized health service provider can perform this action");
        _;
    }

    modifier canAddHealthRecord(address patientAddress) {
        require(
            msg.sender == patientAddress || isDoctorOfPatient(msg.sender, patientAddress),
            "Only the patient or their appointed doctor can add a health record."
        );
        _;
    }

    modifier canViewHealthRecord(address patientAddress) {
        require(
            msg.sender == patientAddress || isDoctorOfPatient(msg.sender, patientAddress),
            "Access restricted to the patient or their appointed doctor only"
        );
        _;
    }

    constructor() {
        owner = msg.sender;
        console.log("Decentralized Health Record Management contract deployed by:", msg.sender);
    }


    // Functons to identify roles
    function isOwner(address user) public view returns (bool) {
        return user == owner;
    }
    function isAuthorizedDoctor(address user) public view returns (bool) {
        return doctorAuthorizationStatus[user];
    }

   function isNormalUser(address user) public view returns (bool) {
        return user != owner && !doctorAuthorizationStatus[user];
    }


    function registerDoctor(
        address _doctorAddress,
        string memory _qualification,
        string memory _specialization
    ) public onlyOwner {
        require(!doctorAuthorizationStatus[_doctorAddress], "Doctor already authorized");

        Doctor memory newDoctor = Doctor({
            doctorAddress: _doctorAddress,
            qualification: _qualification,
            specialization: _specialization,
            status: true,
            timeStamp: block.timestamp,
            addedBy: msg.sender
        });

        doctors.push(newDoctor);
        doctorAuthorizationStatus[_doctorAddress] = true;

        emit RegisterAuthorizedDoctor(
            _doctorAddress,
            _qualification,
            _specialization,
            true,
            block.timestamp,
            msg.sender
        );
    }

    function deregisterDoctor(address _doctorAddress, string memory _reason) public onlyOwner {
        require(doctorAuthorizationStatus[_doctorAddress], "Doctor is not authorized");

        bool found = false;
        for (uint256 i = 0; i < doctors.length; i++) {
            if (doctors[i].doctorAddress == _doctorAddress && doctors[i].status==true ) {
                found = true;
                doctors[i].status=false;
                break;
            }
        }
        require(found, "Doctor not found");

        doctorAuthorizationStatus[_doctorAddress] = false;

        emit DeRegisterAuthorizedDoctor(
            _doctorAddress,
            false,
            _reason,
            block.timestamp,
            msg.sender
        );
    }

    function bookAppointment(address _doctorAddress, string memory _reason) public payable {
        require(msg.sender != _doctorAddress, "Self-booking not allowed");

        Doctor memory doc;
        bool found = false;

        for (uint256 i = 0; i < doctors.length; i++) {
            if (doctors[i].doctorAddress == _doctorAddress) {
                doc = doctors[i];
                found = true;
                break;
            }
        }

        require(found, "Doctor not found");
        require(doctorAuthorizationStatus[_doctorAddress], "Doctor is not authorized");

        // Check for existing booking
        address[] memory bookedDoctors = patientToDoctors[msg.sender];
        for (uint256 i = 0; i < bookedDoctors.length; i++) {
            require(bookedDoctors[i] != _doctorAddress, "Appointment with this doctor already booked");
        }
        // Add mappings
        patientToDoctors[msg.sender].push(_doctorAddress);
        doctorToPatients[_doctorAddress].push(msg.sender);

        emit BookAppointmentAndGrantAccess(
            msg.sender,
            _doctorAddress,
            _reason,
            block.timestamp
        );
    }

    function markAppointmentDoneAndRevokeAccess(address _doctorAddress) public {
        address patient = msg.sender;
        address[] storage doctorsList = patientToDoctors[patient];
        bool found = false;

        for (uint256 i = 0; i < doctorsList.length; i++) {
            if (doctorsList[i] == _doctorAddress) {
                doctorsList[i] = doctorsList[doctorsList.length - 1];
                doctorsList.pop();
                found = true;
                break;
            }
        }

        require(found, "Doctor not found in your appointment list");

        // removing patient from doctor's mapping also
        address[] storage patients = doctorToPatients[_doctorAddress];
        for (uint256 j = 0; j < patients.length; j++) {
            if (patients[j] == patient) {
                patients[j] = patients[patients.length - 1];
                patients.pop();
                break;
            }
        }

        emit MarkAppointmentDoneAndRevokeAccess(
            msg.sender,
            _doctorAddress,
            block.timestamp
        );
    }


    function addHealthRecord(
        address _patientAddress,
        int16 _height,
        int16 _weight,
        string memory _bloodPressure,
        string memory _cholesterol,
        string memory _diagnosis,
        string memory _treatment
    ) public canAddHealthRecord(_patientAddress) {
        uint256 newRecordId = patientHealthRecords[_patientAddress].length + 1;

        HealthRecord memory newRecord = HealthRecord({
            recordId: newRecordId,
            patientAddress: _patientAddress,
            height: _height,
            weight: _weight,
            bloodPressure: _bloodPressure,
            cholesterol: _cholesterol,
            diagnosis: _diagnosis,
            treatment: _treatment,
            timeStamp: block.timestamp,
            addedBy: msg.sender
        });

        patientHealthRecords[_patientAddress].push(newRecord);

        emit AddHealthRecord(
            newRecordId,
            _patientAddress,
            _height,
            _weight,
            _bloodPressure,
            _cholesterol,
            _diagnosis,
            _treatment,
            block.timestamp,
            msg.sender
        );
    }

    function viewHealthRecords(address _patientAddress) public view canViewHealthRecord(_patientAddress) returns (HealthRecord[] memory) {
        return patientHealthRecords[_patientAddress];
    }

    function getAllDoctors() public view returns (Doctor[] memory) {
        return doctors;
    }


    function getAssignedDoctorsOfPatient(address _patientAddress) public view returns (address[] memory) {
        return patientToDoctors[_patientAddress];
    }

    function getPatientsOfDoctor(address _doctorAddress) public view returns (address[] memory) {
        return doctorToPatients[_doctorAddress];
    }

   // Utility Functon
    function isDoctorOfPatient(address _doctor, address _patient) internal view returns (bool) {
        address[] memory doctorsOfPatient = patientToDoctors[_patient];
        for (uint256 i = 0; i < doctorsOfPatient.length; i++) {
            if (doctorsOfPatient[i] == _doctor) {
                return true;
            }
        }
        return false;
    }

}
