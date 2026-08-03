import React, { useState, useEffect } from 'react';
import { motion } from 'framer-motion';
import styled from 'styled-components';
import biometricAuth from '../services/biometricAuth';

const Container = styled.div`
  min-height: 100vh;
  background: #050607;
  color: #fff;
  padding: 24px 20px;
  max-width: 600px;
  margin: 0 auto;
`;

const Title = styled.h1`
  font-family: 'Outfit', sans-serif;
  font-size: 24px;
  font-weight: 700;
  margin: 0 0 24px;
`;

const Card = styled(motion.div)`
  background: #1c1c1e;
  border-radius: 16px;
  padding: 20px;
  border: 1px solid #2c2c2e;
  margin-bottom: 16px;
`;

const CardTitle = styled.h3`
  font-family: 'Outfit', sans-serif;
  font-size: 16px;
  font-weight: 600;
  margin: 0 0 12px;
`;

const CardDesc = styled.p`
  font-size: 13px;
  color: #8e8e93;
  margin: 0 0 16px;
`;

const Toggle = styled.label`
  display: flex;
  align-items: center;
  justify-content: space-between;
  cursor: pointer;
`;

const ToggleLabel = styled.span`
  font-size: 14px;
`;

const Switch = styled.div`
  width: 44px;
  height: 26px;
  border-radius: 13px;
  background: ${props => props.on ? '#34c759' : '#3a3a3c'};
  position: relative;
  transition: background 0.2s;
  flex-shrink: 0;

  &::after {
    content: '';
    position: absolute;
    top: 2px;
    left: ${props => props.on ? '20px' : '2px'};
    width: 22px;
    height: 22px;
    border-radius: 50%;
    background: #fff;
    transition: left 0.2s;
  }
`;

const Button = styled.button`
  background: #ffcc00;
  color: #050607;
  border: none;
  border-radius: 12px;
  padding: 12px 24px;
  font-size: 14px;
  font-weight: 600;
  cursor: pointer;
  width: 100%;
  transition: opacity 0.2s;

  &:hover { opacity: 0.9; }
  &:disabled { opacity: 0.5; cursor: not-allowed; }
`;

const SocialButton = styled.button`
  background: #1c1c1e;
  color: #fff;
  border: 1px solid #2c2c2e;
  border-radius: 12px;
  padding: 12px 24px;
  font-size: 14px;
  font-weight: 600;
  cursor: pointer;
  width: 100%;
  margin-bottom: 8px;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 8px;
  transition: background 0.2s;

  &:hover { background: #2c2c2e; }
`;

const Status = styled.div`
  font-size: 12px;
  color: ${props => props.success ? '#34c759' : '#ff3b30'};
  margin-top: 8px;
`;

const SecuritySettings = () => {
  const [biometricAvailable, setBiometricAvailable] = useState(false);
  const [biometricEnabled, setBiometricEnabled] = useState(false);
  const [mfaEnabled, setMfaEnabled] = useState(false);
  const [totpSecret, setTotpSecret] = useState(null);
  const [totpCode, setTotpCode] = useState('');
  const [status, setStatus] = useState(null);

  useEffect(() => {
    checkBiometric();
  }, []);

  const checkBiometric = async () => {
    const result = await biometricAuth.checkBiometricAvailability();
    setBiometricAvailable(result.available);
  };

  const handleBiometricToggle = async () => {
    try {
      if (!biometricEnabled) {
        await biometricAuth.authenticateWithBiometrics();
        await biometricAuth.enableBiometricLogin('current_user');
        setBiometricEnabled(true);
        setStatus({ success: true, msg: 'Biometric login enabled' });
      } else {
        await biometricAuth.disableBiometricLogin('current_user');
        setBiometricEnabled(false);
        setStatus({ success: true, msg: 'Biometric login disabled' });
      }
    } catch (err) {
      setStatus({ success: false, msg: err.message });
    }
  };

  const handleMFAToggle = async () => {
    if (!mfaEnabled) {
      try {
        const result = await biometricAuth.generateTOTPSecret('current_user');
        setTotpSecret(result);
        setMfaEnabled(true);
        setStatus({ success: true, msg: 'Scan the QR code in your authenticator app' });
      } catch (err) {
        setStatus({ success: false, msg: err.message });
      }
    } else {
      try {
        await biometricAuth.disableMFA('current_user', totpCode);
        setMfaEnabled(false);
        setTotpSecret(null);
        setStatus({ success: true, msg: 'MFA disabled' });
      } catch (err) {
        setStatus({ success: false, msg: err.message });
      }
    }
  };

  return (
    <Container>
      <Title>Security & Authentication</Title>

      <Card initial={{ opacity: 0, y: 10 }} animate={{ opacity: 1, y: 0 }}>
        <CardTitle>Biometric Login</CardTitle>
        <CardDesc>
          Use Face ID or Touch ID to quickly and securely access your Milli account.
        </CardDesc>
        <Toggle onClick={handleBiometricToggle}>
          <ToggleLabel>{biometricAvailable ? 'Enable Biometric Login' : 'Biometric not available on this device'}</ToggleLabel>
          <Switch on={biometricEnabled} />
        </Toggle>
      </Card>

      <Card initial={{ opacity: 0, y: 10 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: 0.05 }}>
        <CardTitle>Two-Factor Authentication (MFA)</CardTitle>
        <CardDesc>
          Add an extra layer of security with a TOTP authenticator app (Google Authenticator, Authy, etc.).
        </CardDesc>
        {totpSecret && !mfaEnabled && (
          <div style={{ marginBottom: 16 }}>
            <p style={{ fontSize: 13, color: '#8e8e93', marginBottom: 8 }}>
              Secret: <code style={{ color: '#ffcc00' }}>{totpSecret.secret}</code>
            </p>
            <input
              type="text"
              placeholder="Enter 6-digit code"
              value={totpCode}
              onChange={(e) => setTotpCode(e.target.value)}
              style={{
                background: '#050607', border: '1px solid #2c2c2e', borderRadius: 8,
                padding: '10px 14px', color: '#fff', fontSize: 14, width: '100%',
                marginBottom: 12,
              }}
            />
            <Button onClick={async () => {
              try {
                await biometricAuth.verifyTOTP('current_user', totpCode);
                setMfaEnabled(true);
                setStatus({ success: true, msg: 'MFA enabled successfully' });
              } catch (err) {
                setStatus({ success: false, msg: 'Invalid code' });
              }
            }}>Verify Code</Button>
          </div>
        )}
        <Toggle onClick={handleMFAToggle}>
          <ToggleLabel>{mfaEnabled ? 'Disable MFA' : 'Enable MFA'}</ToggleLabel>
          <Switch on={mfaEnabled} />
        </Toggle>
      </Card>

      <Card initial={{ opacity: 0, y: 10 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: 0.1 }}>
        <CardTitle>Social Login</CardTitle>
        <CardDesc>Link your social accounts for faster sign-in.</CardDesc>
        <SocialButton onClick={() => biometricAuth.signInWithApple({})}>
          Sign in with Apple
        </SocialButton>
        <SocialButton onClick={() => biometricAuth.signInWithGoogle({})}>
          Sign in with Google
        </SocialButton>
      </Card>

      {status && (
        <Status success={status.success}>{status.msg}</Status>
      )}
    </Container>
  );
};

export default SecuritySettings;